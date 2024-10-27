/// [Result]: успешное возвращение значения типа [T].
final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

/// [Result]: возникла ошибка типа [E].
final class Err<T, E> extends Result<T, E> {
  final E value;
  const Err(this.value);
}

/// Обозначает собой либо успешное значение [T], либо возникшую ошибку [E].
/// Отлично подойдёт как возвращаемое значение функции, которая может
/// вместо значения вернуть ошибку.
sealed class Result<T, E> {
  const Result();
}
