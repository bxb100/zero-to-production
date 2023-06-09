use actix_web::HttpResponse;

pub async fn health_check() -> HttpResponse {
    HttpResponse::Ok().finish()
}

#[tokio::test]
async fn health_check_succeeds() {
    let response = health_check().await;
    // This requires changing the return type of `health_check`
    // from `impl Responder` to `HttpResponse` to compile
    // You also need to import it with `use actix_web::HttpResponse`!
    assert!(response.status().is_success())
}
