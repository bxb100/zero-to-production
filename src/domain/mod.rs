// By default, everything is private, with two exceptions: Associated items in a pub Trait are public by default; Enum variants in a pub enum are also public by default.
// https://doc.rust-lang.org/reference/visibility-and-privacy.html

pub use new_subscriber::NewSubscriber;
pub use subscriber_email::SubscriberEmail;
pub use subscriber_name::SubscriberName;

mod new_subscriber;
mod subscriber_email;
mod subscriber_name;
