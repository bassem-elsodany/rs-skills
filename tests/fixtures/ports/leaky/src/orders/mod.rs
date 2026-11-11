//! fixture: business code that talks to the products directly.
use sqlx::PgPool;

#[derive(sqlx::FromRow)]
pub struct Order { pub id: i64 }

pub async fn find(pool: &PgPool, id: i64) -> Result<Order, sqlx::Error> {
    sqlx::query_as("SELECT id FROM orders WHERE id = $1").bind(id).fetch_one(pool).await
}

#[cfg(feature = "redis")]
pub fn cache() -> redis::Client { redis::Client::open("redis://127.0.0.1/").unwrap() }
