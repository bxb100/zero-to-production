//! tests/health_check.rs

use std::net::TcpListener;

use actix_web::http::header::ContentType;
use actix_web::test;

use zero2prod::{create_app, run};

// `tokio::test` is the testing equivalent of `tokio::main`.
// It also spares you from having to specify the `#[test]` attribute. //
// You can inspect what code gets generated using
// `cargo expand --test health_check` (<- name of the test file)
#[tokio::test]
async fn health_check_works() {
    // Arrange
    let address = spawn_app();
    // We need to bring in `reqwest`
    // to perform HTTP requests against our application.
    let client = reqwest::Client::new();
    // Act
    let response = client
        .get(&format!("{}/health_check", &address))
        .send()
        .await
        .expect("Failed to execute request.");
    // Assert
    assert!(response.status().is_success());
    assert_eq!(Some(0), response.content_length());
}

// Launch our application in the background ~somehow~
fn spawn_app() -> String {
    let listener = TcpListener::bind("127.0.0.1:0").expect("Failed to bind random port");
    let port = listener.local_addr().unwrap().port();
    let server = run(listener).expect("Failed to bind address");

    tokio::spawn(server);
    // We return the application address to the caller!
    format!("http://127.0.0.1:{}", port)
}

// actix define integration test
#[actix_web::test]
async fn test_actix_web_work() {
    let app = test::init_service(create_app()).await;
    let request = test::TestRequest::get()
        .uri("/health_check")
        .insert_header(ContentType::plaintext())
        .to_request();
    let response = test::call_service(&app, request).await;
    assert!(response.status().is_success());
    assert_eq!(0, test::read_body(response).await.len());
}
