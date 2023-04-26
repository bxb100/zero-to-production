//! tests/health_check.rs

use std::net::TcpListener;

use actix_web::http::header::ContentType;
use actix_web::test;
use reqwest::header::CONTENT_TYPE;

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

macro_rules! test_form {

    ($body:expr, $($args:expr),+) => {
        let app_address = spawn_app();
        let client = reqwest::Client::new();

        let response = client
            .post(&format!("{}/subscriptions", &app_address))
            .header(CONTENT_TYPE, "application/x-www-form-urlencoded")
            .body($body)
            .send()
            .await
            .expect("Failed to execute request.");

        // Assert
        assert_eq!(response.status().as_u16(), $($args),+);
    };
}

#[tokio::test]
async fn subscribe_return_a_200_for_valid_form_data() {
    // Act
    let body = "name=le%20guin&email=ursula_le_guin%40gmail.com";

    // Assert
    test_form!(body, 200);
}

#[tokio::test]
async fn subscribe_return_a_400_when_data_is_missing() {
    // Arrange
    let test_cases = vec![
        ("name=le%20guin", "missing the email"),
        ("email=ursula_le_guin%40gmail.com", "missing the name"),
        ("", "missing both name and email"),
    ];

    for (invalid_body, error_message) in test_cases {
        // Assert
        test_form!(
            invalid_body,
            400,
            // Additional customised error message on test failure
            "The API did not fail with 400 Bad Request when the payload was {}.",
            error_message
        );
    }
}
