import 'dart:io';

/// This means that a variable with type nat should be greater than 0
@Refinement(identifier: 'x', predicate: 'x > 0')
typedef nat = int;

/// This means that a variable with type shortList
/// (which is a List<T>) should be shorter than 10
///
/// We will accept polymorphism of the List and we will allow it
/// to accept any type. At compile time we check whether the type
/// passed to the list is one we handle, if it is we check
/// whatever is added to the list, if not -- skip and verify other predicates.
@Refinement(identifier: 'x', predicate: 'length(x) <= 10')
typedef ShortList<T> = List<T>;

@Refinement(identifier: 'x', predicate: 'length(x) > 10 && length(x) <= 20')
typedef MediumSizedList<T> = List<T>;

/// Apparently also a valid refinement
@Refinement(identifier: 'x', predicate: 'x')
typedef TrueBool = bool;

/// Apparently also a valid refinement
@Refinement(identifier: 'x', predicate: '!x')
typedef FalseBool = bool;

void main() {
  /// This gives us a conjuction x > 0 && x < 10
  @Refinement(identifier: 'x', predicate: 'x < 10')
  nat variableLessThanTen = 5;
  print(variableLessThanTen);

  // Cannot do that since it is not compile time information.
  // We now this only at runtime which makes sense
  // On the right is the x < 11
  // This is actually unsafe.
  variableLessThanTen = addOne(variableLessThanTen);

  /// Assume input comes in the value of which we don't know
  final int number = int.parse(stdin.readLineSync()!);

  if (number > 0) {
    /// Not proved safe, but not proved unsafe either
    variableLessThanTen = number;
  }

  if (number < 10) {
    /// Not proved safe, but not proved unsafe either
    variableLessThanTen = number;
  }

  if (number < 0 && number > 10) {
    /// Proven safe
    variableLessThanTen = number;
  } else {
    /// Proven not safe
    variableLessThanTen = number;
  }

  final ShortList<nat> items = [];

  /// Should catch as an error in compile time,
  /// since the list was just initialized and we know its length to be 0
  print(items[1]);
  items[2] = 5;

  for (int i = 0; i < 20; i++) {
    /// Should report an error at compile time, since due to these operations
    /// the list length will become > 10
    items.add(i);
  }

  items.clear();

  while (items.length < 10) {
    /// Should pass
    items.add(5);
  }

  items.clear();

  /// Should break since the list only accepts nats (int refined to be gt10)
  items.add(-1);

  /// If no initialization we wait for when it is initialized to check the
  /// initial size, since the list CANNOT be empty
  MediumSizedList<nat> filledItems;

  /// Doesn't throw at compile time
  filledItems = [for (int i = 0; i < 15; i++) 5];
  filledItems = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

  /// Does
  filledItems = [];

  /// Not supported
  filledItems = List.filled(15, 0);

  print(filledItems);
}

/// We can accept both named and positional parameters into functions
@FunctionRefinement(
  parameters: ['x'],
  namedParameters: {'z': 'innerIdentifier'},
  returnIdentifier: 'y',
  predicate: 'y > x && x + innerIdentifier == y',
)
int addOne(nat x, {nat? z}) {
  return x + (z ?? 1);
}

/// Strings as parameters because there's no reasonable way to pass
/// declarations/expressions as parameters.
///
/// The analyzer already knows what is being annotated (we can get the type
/// and the name from there). Identifier is just an inner name for a variable
/// we're using, so for example we can do:
///
/// ```
/// @Refinement('x', 'x > 0')
/// int y;
/// ```
///
/// And the analyzer will now that `x` in this scenario is just a substitution
/// for `y` or any other identifier for that matter
class Refinement {
  const Refinement({required this.identifier, required this.predicate});
  final String identifier;
  final String predicate;
}

/// This will check at compile time whether parameters passed to the annotation
/// match with the parameters in actual function being annotated
class FunctionRefinement extends Refinement {
  const FunctionRefinement({
    this.parameters = const [],
    this.namedParameters,
    required this.returnIdentifier,
    required this.predicate,
  }) : super(predicate: predicate, identifier: returnIdentifier);

  /// Doesn't matter what names are given to the parameters, since named
  /// parameters are always in the same order they are just substitutions
  /// similarly to how identifier works in [Refinement]
  final List<String> parameters;

  /// The key is the actual parameter name in the function declaration.
  ///
  /// The value is the identifier that will be used in predicates
  final Map<String, String>? namedParameters;
  final String returnIdentifier;
  @override
  final String predicate;
}
