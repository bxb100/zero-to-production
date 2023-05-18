use std::net::TcpListener;

use actix_web::body::MessageBody;
use actix_web::dev::{Server, ServiceFactory, ServiceRequest, ServiceResponse};
use actix_web::middleware::Logger;
use actix_web::{web, App, Error, HttpServer};
use sqlx::PgPool;

use crate::routes::{health_check, index, subscribe};

pub fn routes() -> App<
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
pub fn run(listener: TcpListener, connection: PgPool) -> std::io::Result<Server> {
    // Wrap the connection in a smart pointer
    let db_pool = web::Data::new(connection);
    let server =
        HttpServer::new(move || routes().wrap(Logger::default()).app_data(db_pool.clone()))
            .listen(listener)?
            .run();
    Ok(server)
}
