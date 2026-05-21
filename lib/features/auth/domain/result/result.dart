sealed class Result<S, F> {
  const Result();

  bool get isSuccess => this is Success<S, F>;

  bool get isFailure => this is FailureResult<S, F>;
}

class Success<S, F> extends Result<S, F> {
  const Success(this.data);

  final S data;
}

class FailureResult<S, F> extends Result<S, F> {
  const FailureResult(this.failure);

  final F failure;
}
