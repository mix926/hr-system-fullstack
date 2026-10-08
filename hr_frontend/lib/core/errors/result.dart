// ខ្មែរ: ទីតាំងឯកសារ lib/core/errors/result.dart

// ខ្មែរ: Base class សម្រាប់គ្រប់ប្រភេទកំហុស (Errors) ទាំងអស់នៅក្នុង App
abstract class Failure {
  final String message;
  final String? code;

  Failure({required this.message, this.code});
}

// ខ្មែរ: កំហុសដែលត្រលប់មកពី API (Server) ដូចជា 404, 500, ឬ 422
class ServerFailure extends Failure {
  ServerFailure({required super.message, super.code});
}

// ខ្មែរ: ថ្នាក់ Result ប្រើសម្រាប់ទប់ស្កាត់ការប្រើប្រាស់ try-catch នៅលើ UI
class Result<T> {
  final Failure? _failure;
  final T? _data;
  final bool _isSuccess;

  // ខ្មែរ: បង្កើត Result ពេលទិន្នន័យត្រលប់មកជោគជ័យ
  Result.success(this._data)
      : _isSuccess = true,
        _failure = null;

  // ខ្មែរ: បង្កើត Result ពេលមានកំហុស ឬបរាជ័យ
  Result.failure(this._failure)
      : _isSuccess = false,
        _data = null;

  // ខ្មែរ: អនុគមន៍ fold បង្ខំអោយ UI ត្រូវតែសរសេរកូដដោះស្រាយទាំង២ករណីជានិច្ច
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (_isSuccess) {
      return onSuccess(_data as T);
    } else {
      return onFailure(_failure!);
    }
  }
}
//hello