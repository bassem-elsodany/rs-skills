//! fixture: business code behind a port.
pub struct Order { pub id: i64 }
pub struct OrderError;
pub trait OrderStore: Send + Sync {
    fn find(&self, id: i64) -> impl std::future::Future<Output = Result<Order, OrderError>> + Send;
}
