//! # Design Contract
//! **Role:** Policy decision core: request model, four-valued `Decision`, combining algorithms, and the enforcement rule "only an explicit Permit passes".
//! **Patterns:** PDP/PEP split (rs-domain-policy) · Strategy (combining algorithm) · Decision trail for audit
//! **Invariants:** `Indeterminate` and `NotApplicable` never pass `enforce`; an empty rule set denies; every `combine` call returns the trail of which rule said what.
//! **Extend by:** add a `Rule` impl (attribute/role/relationship check) or a `Combine` variant with its table-driven test; never add a boolean "allow_if_error".
//! **Avoid:** evaluating policy inside handlers; defaulting to Permit on error; mutating the request while evaluating.
//! **Skills:** rs-domain-policy, rs-error-handling (`err-fail-closed`), rs-testing

use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Decision {
    Permit,
    Deny,
    NotApplicable,
    /// Evaluation failed (missing attribute, engine error). Treated as Deny by `enforce`.
    Indeterminate(String),
}

#[derive(Debug, Clone, Default)]
pub struct Request {
    pub subject: BTreeMap<String, String>,
    pub resource: BTreeMap<String, String>,
    pub action: String,
}

pub trait Rule: Send + Sync {
    fn id(&self) -> &str;
    fn evaluate(&self, req: &Request) -> Decision;
}

#[derive(Debug, Clone, Copy)]
pub enum Combine {
    DenyOverrides,
    PermitOverrides,
    FirstApplicable,
}

pub fn combine(alg: Combine, rules: &[Box<dyn Rule>], req: &Request) -> (Decision, Vec<String>) {
    let mut trail = Vec::new();                               // which rules decided what: the audit trail
    let mut saw_permit = false;
    let mut saw_indeterminate: Option<String> = None;
    for r in rules {
        let d = r.evaluate(req);
        trail.push(format!("{}={:?}", r.id(), d));
        match (alg, d) {
            (Combine::DenyOverrides, Decision::Deny) => return (Decision::Deny, trail),
            (Combine::PermitOverrides, Decision::Permit) => return (Decision::Permit, trail),
            (Combine::FirstApplicable, d @ (Decision::Permit | Decision::Deny)) => return (d, trail),
            (_, Decision::Permit) => saw_permit = true,
            (_, Decision::Indeterminate(why)) => {
                saw_indeterminate.get_or_insert(why);
            }
            _ => {}
        }
    }
    let out = match alg {
        Combine::DenyOverrides => match (saw_indeterminate, saw_permit) {
            (Some(why), _) => Decision::Indeterminate(why),   // an error could have been a Deny: do not permit
            (None, true) => Decision::Permit,
            (None, false) => Decision::NotApplicable,
        },
        Combine::PermitOverrides => saw_indeterminate.map_or(Decision::NotApplicable, Decision::Indeterminate),
        Combine::FirstApplicable => Decision::NotApplicable,
    };
    (out, trail)
}

/// The Policy Enforcement Point's last word: only an explicit Permit gets through.
#[must_use]
pub fn enforce(d: &Decision) -> bool {
    matches!(d, Decision::Permit)
}

#[cfg(test)]
mod tests {
    use super::*;
    struct Always(&'static str, Decision);
    impl Rule for Always {
        fn id(&self) -> &str { self.0 }
        fn evaluate(&self, _: &Request) -> Decision { self.1.clone() }
    }
    fn rules(v: Vec<(&'static str, Decision)>) -> Vec<Box<dyn Rule>> {
        v.into_iter().map(|(i, d)| Box::new(Always(i, d)) as Box<dyn Rule>).collect()
    }

    #[test]
    fn deny_overrides_beats_permit() {
        let r = rules(vec![("a", Decision::Permit), ("b", Decision::Deny)]);
        assert_eq!(combine(Combine::DenyOverrides, &r, &Request::default()).0, Decision::Deny);
    }
    #[test]
    fn indeterminate_never_permits() {
        let r = rules(vec![("a", Decision::Permit), ("b", Decision::Indeterminate("missing attr".into()))]);
        let (d, trail) = combine(Combine::DenyOverrides, &r, &Request::default());
        assert!(!enforce(&d));
        assert_eq!(trail.len(), 2);
    }
    #[test]
    fn no_rule_applies_is_denied_at_the_enforcement_point() {
        let (d, _) = combine(Combine::DenyOverrides, &[], &Request::default());
        assert_eq!(d, Decision::NotApplicable);
        assert!(!enforce(&d));                                   // default deny
    }
}
