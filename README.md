# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

- Ruby version

- System dependencies

- Configuration

- Database creation

- Database initialization

- How to run the test suite

- Services (job queues, cache servers, search engines, etc.)

- Deployment instructions

- ...

# ThreeDFour Game

A 3D Connect Four game implementation.

## System Requirements

- Ruby version: 3.3.0
- Rails version: 8.0.1
- PostgreSQL

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Setup database:
   ```bash
   rails db:create db:migrate db:seed
   ```

## Testing

The application uses RSpec for testing. There are several types of tests:

### Running Tests

- Run all tests (excluding performance):

  ```bash
  bundle exec rspec
  ```

- Run specific test file:
  ```bash
  bundle exec rspec spec/path/to/file_spec.rb
  ```

### Performance Tests

Performance tests are located in `spec/performance/` and are excluded from regular test runs.

- Run performance tests:

  ```bash
  RUN_PERFORMANCE_TESTS=true bundle exec rspec spec/performance
  ```

- Run all tests including performance:
  ```bash
  RUN_PERFORMANCE_TESTS=true bundle exec rspec
  ```

Performance tests include:

- Move serialization benchmarks
- Memory usage analysis
- Batch processing tests

Note: Some performance tests are marked with `:skip_in_ci` and won't run in CI environments.

### Test Categories

- Models: `spec/models/`
- System Tests: `spec/system/`
- Request Tests: `spec/requests/`
- Feature Tests: `spec/features/`
- Performance Tests: `spec/performance/`

## Development

Start the Rails server:

```bash
rails server
```

## Services

- Database: PostgreSQL
- Testing: RSpec
- Authentication: Devise
- State Machine: AASM
