mod health_check;
mod subscriptions;

pub use health_check::*;
pub use subscriptions::*;

pub async fn index() -> String {
    "Hello World!".to_string()
}
