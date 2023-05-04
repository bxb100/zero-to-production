use std::net::TcpListener;

use actix_web::body::MessageBody;
use actix_web::dev::{Server, ServiceFactory, ServiceRequest, ServiceResponse};
use actix_web::{web, App, Error, HttpResponse, HttpServer};

async fn health_check() -> HttpResponse {
    HttpResponse::Ok().finish()
}

#[derive(serde::Deserialize)]
struct FormData {
    email: String,
    name: String,
}

async fn subscribe(_form: web::Form<FormData>) -> HttpResponse {
    HttpResponse::Ok().finish()
}

async fn index() -> String {
    "Hello World!".to_string()
}

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

// We need to mark `run` as public.
// It is no longer a binary entrypoint, therefore we can mark it as async // without having to use any proc-macro incantation.
pub fn run(listener: TcpListener) -> std::io::Result<Server> {
    let server = HttpServer::new(create_app).listen(listener)?.run();
    Ok(server)
}

#[tokio::test]
async fn health_check_succeeds() {
    let response = health_check().await;
    // This requires changing the return type of `health_check`
    // from `impl Responder` to `HttpResponse` to compile
    // You also need to import it with `use actix_web::HttpResponse`!
    assert!(response.status().is_success())
}
