//! fixture: the only place that names sqlx.
use sqlx::PgPool;
#[derive(sqlx::FromRow)]
struct OrderRow { id: i64 }
pub struct PgOrders(pub PgPool);
pub fn query() -> &'static str { "SELECT id FROM orders WHERE id = $1" }
