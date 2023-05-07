use std::net::TcpListener;

use actix_web::body::MessageBody;
use actix_web::dev::{Server, ServiceFactory, ServiceRequest, ServiceResponse};
use actix_web::{web, App, Error, HttpServer};

use crate::routes::{health_check, index, subscribe};

pub fn create_app() -> App<
    impl ServiceFactory<
        ServiceRequest,
        Config = (),
        Response = ServiceResponse<impl MessageBody>,
        Error = Error,
        InitError = (),
    >,
> {
    App::new()
        .route("/", web::get().to(index))
        .route("/health_check", web::get().to(health_check))
        .route("/subscriptions", web::post().to(subscribe))
}

/// We need to mark `run` as public.
/// It is no longer a binary entrypoint, therefore we can mark it as async // without having to use any proc-macro incantation.
pub fn run(listener: TcpListener) -> std::io::Result<Server> {
    let server = HttpServer::new(create_app).listen(listener)?.run();
    Ok(server)
}
