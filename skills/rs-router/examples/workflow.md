# Workflow Examples

> Worked routing examples for rs-router

## Example 1: Error Code with Domain Context

```
User: "Why am I getting E0382 in my trading system?"

Analysis:
1. Entry: Layer 1 (E0382 = ownership/move error)
2. Load: rs-ownership skill
3. Context: "trading system" → rs-domain-fintech

Trace UP ↑:
- E0382 in trading context
- Check rs-domain-fintech: "immutable audit records"
- Finding: Trading data should be shared, not moved

Response:
"E0382 indicates a value was moved when still needed.
In a trading system (rs-domain-fintech), transaction records
should be immutable and shareable for audit purposes.

Instead of cloning, consider:
- Arc<TradeRecord> for shared immutable access
- This aligns with financial audit requirements

See: rs-ownership (Trace Up section),
     rs-domain-fintech (Audit Requirements)"
```

## Example 2: Design Question

```
User: "How should I handle user authentication?"

1. Entry: Layer 2 (design question)
2. Trace UP to Layer 3: rs-domain-web constraints
3. Load: rs-domain-web skill (security, stateless HTTP)
4. Trace DOWN: rs-error-handling, rs-concurrency
5. Answer: JWT with proper error types, async handlers
```

## Example 3: Comparative Query

```
User: "Compare tokio and async-std"

1. Detect: "compare" → Enable negotiation
2. Load both runtime knowledge sources
3. Assess confidence for each
4. Synthesize with disclosed gaps
5. Answer: Structured comparison table
```

## Example 4: Multi-Layer Trace

```
User: "My web API reports Rc cannot be sent between threads"

1. Entry: Layer 1 (Send/Sync error)
2. Load: rs-concurrency
3. Detect: "web API" → rs-domain-web
4. Dual-skill loading:
   - rs-concurrency: Explain Send/Sync bounds
   - rs-domain-web: Web state management patterns
5. Answer: Use Arc instead of Rc, or move to thread-local
```

## Example 5: Intent Analysis Request

```
User: "Analyze this question: How do I share state in actix-web?"

Analysis Steps:
1. Extract Keywords: share, state, actix-web
2. Identify Entry Layer: Layer 1 (sharing = concurrency) + Layer 3 (actix-web = web)
3. Map to Skills: rs-concurrency, rs-domain-web
4. Report:
   - Layer 1: Concurrency (state sharing mechanisms)
   - Layer 3: Web domain (HTTP handler patterns)
   - Suggested trace: L1 → L3
5. Invoke: rs-concurrency first, then rs-domain-web
```
