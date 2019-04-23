


//Vi bruger ikke blocs lige nu men måske senere
// https://www.youtube.com/watch?v=LeLrsnHeCZY

class RatingsState {
  final List<int> ratings;

  //private constructor - Class should only be made by factories
  const RatingsState({this.ratings});

  //initial factory used when app starts
  factory RatingsState.initial() => RatingsState(ratings: []); //muligvis skift [] til læs fra fil initialiser

}
