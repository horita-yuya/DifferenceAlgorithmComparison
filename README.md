# Heckel
[Japaneses description (Myers comming soon.)](/README.ja.md)

Let's think about getting difference between Array O and Array N.

In Heckel Algorithm, these three datas are important.

1. symbol table
2. old element references
3. new element references

First, symbol table are described. Symbol table is Dictionary whose key is the elements included in both Array O and N. Like below, it's key is a hash value of each elements and value is a symbol table entry implementally.

Because the key is the hash value of each elements, you can get same value if elements are same.
Using this feature, symbol table manages all elements appearing in Array O and N.

Symbol table entry is a dictionary value which has two Counters, Counter for Array O and N, and index of the key element in Array O, called OLNO.

In fact, *.zero .one, .many* cases are enough for Counter. In Heckel Algorithm, the elements which included in both arrays and the number of them in each arrays is just one, called *shared unique element*, will be source for getting difference. So Counter does not need having actual number.

Implementally, OLNO can be an associated value of case .one, like below.

```swift
// 1 is the only shared unique element.
let O: [Int] = [1, 2, 3, 3] // 1 and 2: unique, 3: not unique
let N: [Int] = [1, 2, 2, 3] // 1 and 3: unique, 2: not unique
```

```swift
<E: Hashable>

var symbolTable: [Int: SymbolTableEntry] = [:]

enum Counter {
  case zero
  case one(index: Int) // OLNO
  case many

  mutating func increment(withIndex index: Int) {
    switch self {
      case .zero:
        self = .one(index: index)

        default:
        self = .many
      }
  }
}

class SymbolTableEntry {
  var oldCounter: Counter
  var newCounter: Counter
}
```
Summarize for `symbol table`
- How many elements are included in both arrays? -> `Counter`
- Where is the element included in array O? -> `associated value of case .one`

symbol table is a dictionary data manages these information

Next, describing about `2, 3: old element references, new element references`. First of all, these two arrays are correspoding to array O and N one to one. Let each arrays OA and NA.

Now, only symbol table has information of array O and N except O and N themselves. It has the information as a key. Newly, arrays OA and NA will manage a reference `where the correspoding element exists`. The candidates of reference are .theOther or .symbolTable. For array O, .theOther reference means array N and vice versa.

- .symbolTable reference has the entry for symbol table as an associated value.
- .theOther reference has the index of the other array as an associated value.

```swift
enum ElementReference {
  case symbolTable(entry: SymbolTableEntry)
  case theOther(index: Int)
}
```

Here, Summarize all characters.
- symbol table :
  - Dictionary whose key is the hash value of elements in array O and N
  - only one table are shared by O and N.
  - symbol table entry: the value of symbol table
    - How many elements are included in both arrays?
    - Where is the element included in array O?
- Old
  - O: original old array (oldArray)
  - OA: element reference array is correspoding to array O one to one (oldElementReferences)
- New
  - N: original new array (newArray)
  - NA: element reference array is correspoding to array N one to one (newElementReferences)

The name inside parenthesis is a variable name written in Swift.
No other characters appears from this. The essense of Heckel Algorithm is combining these data and the steps described below.

## <a name="6steps"> 6-Steps

### Step-1

Let's proceed to Step-1.
Here, all elements in array N are registered to symbol table.
```swift
newArray.forEach { element in
  let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
  entry.newCounter.increment(withIndex: 0)
  newElementReferences.append(.symbolTable(entry: entry))
  symbolTable[element.hashValue] = entry
}
```
The index 0 passing to increment(withindex:) has no meaning. The argument is OLNO, so for array N, it is meaingless.

### Step-2

In step-2, same operation will be done for array O. Here, OLNO must be considered, so counter is incremented with index.
```swift
oldArray.enumerated().forEach { index, element
  let entry = symbolTable[element.hashValue] ?? TableEntry()
  entry.oldCounter.increment(withIndex: index)
  oldElementReferences.append(.symbolTable(entry: entry))
  symbolTable[element.hashValue] = entry
}
```
The index passing to incremented(withIndex:) is OLNO and it is retained as an associated value of case .one

Two steps out of six have already done.

Next, let's proceed to step-3, 4, 5.

In step-1, 2, only .symbolTable is registered to `newElementReferences and oldElementReferences`. So all references are .symbolTable, of course.

Here, we will shift the reference to .theOther as much as possible, called *shifting operation*. If the element does not exist in the other array, the shifting operation cannot be done. Then, the reference remains as it was, or .symbolTable.

Finally,
- `.symbolTable` -> elements does not exist in the other.
- `.theOther` -> elements are appeared in both arrays.

these relationship are built. The above relationship is equivalent to the below relationship.

- `.symbolTable` -> `delete, insert`
- `.theOther` -> `move`

### Step-3

In step-3, *shifting operation* is performed for *shared unique element*.

```swift
newElementReferences.enumerated().forEach { newIndex, reference in
  guard case let .symbolTable(entry: entry) = reference,
    case .one(let oldIndex) = entry.oldCounter,
    case .one = entry.newCounter else { return }

  newElementReferences[newIndex] = .theOther(index: oldIndex)
  oldElementReferences[oldIndex] = .theOther(index: newIndex)
}
```
It seems that finding a shared element needs a loop inside a loop like below.

```swift
for n in newArray {
  for o in oldArray {
    // finding shared element
  }
}
```

But, in Heckel Algorithm, sharing symbol table and managing OLNO, only single loop will be enough for finding shared element. The former method takes O(N x M) time to accomplish calculation. Avoiding that is very important point.

### Step-4

Next, step-4. In step-3 *shifting operation* was performed only for *shared unique element*. Here, the operation will be done for immediately adjacent to the .theOther pairs.

```swift
newElementReferences.enumerated().forEach { newIndex, _ in
  guard case let .theOther(index: oldIndex) = newElementReferences[newIndex],
    oldIndex < oldElementReferences.count - 1, newIndex < newElementReferences.count - 1,
    case let .symbolTable(entry: newEntry) = newElementReferences[newIndex + 1],
    case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex + 1],
    newEntry === oldEntry else { return }

  newElementReferences[newIndex + 1] = .theOther(index: oldIndex + 1)
  oldElementReferences[oldIndex + 1] = .theOther(index: newIndex + 1)
}
```
Implementally, the next index of elements which have .theOther reference will be the target of the operation.

### Step-5

Same operation will be done in descending order. This means the previous index will be the target.
```swift
newElementReferences.enumerated().reversed().forEach { newIndex, _ in
  guard case let .theOther(index: oldIndex) = newElementReferences[newIndex],
    oldIndex > 0, newIndex > 0,
    case let .symbolTable(entry: newEntry) = newElementReferences[newIndex - 1],
    case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex - 1],
    newEntry === oldEntry else { return }

  newElementReferences[newIndex - 1] = .theOther(index: oldIndex - 1)
  oldElementReferences[oldIndex - 1] = .theOther(index: newIndex - 1)
}
```

Five steps out of six have already done.

### Step-6

In step-1 to step-5, arrays OA and NA were determined. Difference scripts, .delete, .insert, .move, are converted from the references contained in OA and NA.

- reference to .symbolTable = not shared element
- reference to .theOther = shared element

Apparently, the above relationship is built.

- Not shared element included in array O must be `deleted`.
- Not shared element included in array N must be `inserted`.
- Shared element must be `moved` to adjust index.

References can be converted like above.
In step-6, the convertion will be done.

```swift
enum Difference<E> {
  case delete(element: E, index: Int)
  case insert(element: E, index: Int)
  case move(element: E, fromIndex: Int, toIndex: Int)
}

var differences: [Difference<T>] = []

oldElementReferences.enumerated().forEach { oldIndex, reference in
  guard case .symbolTable = reference else { return }
  differences.append(.delete(element: oldArray[oldIndex], index: oldIndex))
}

newElementReferences.enumerated().forEach { newIndex, reference in
  switch reference {
    case .symbolTable:
      differences.append(.insert(element: newArray[newIndex], index: newIndex))

    case let .theOther(index: oldIndex):
      differences.append(.move(element: newArray[newIndex], fromIndex: oldIndex, toIndex: newIndex))
  }
}
```

Here, we need be careful for `move` script. Assuming that array O and N are completely same. In this case, all references will be .theOther, so all scripts will be move. But this move's fromIndex and toIndex are same.

They are useless move scripts. Some index restrictions will be needed for removing such verbose move commands.

Like this, the difference got by Heckel Algorithm cannot be shortest. The major characteristics of it is linear-time calculation.

#  Myers Difference Algorithm

Myers Difference Algorithm is an algorithm that finds a longest common subsequence(LCS) or shortest edit scripts(SES) of two sequences. MDA can accomplish this in O(ND) time, where N is the sum of the lengths of the two sequences. The common subsequence of two sequences is the sequence of elements that appear in the same order in both sequences.

For example, let's assume you have two arrays:

```
A = [1, 2, 3]
B = [2, 3, 4]
```

The common subsequences of these two arrays are `[2]`, and `[2,3]`. The longest common sequence in this case is `[2,3]`.

## Finding the length of the Longest Common Subsequence with Myers Algorithm on Edit Graph

### Edit Graph

MDA uses an **Edit Graph** to solve the LCS/SES problem. Below is a illustration depicting an edit graph:

<img src='Images/EditGraph.png' height="400">

The x-axis at the top of the graph represents one of the sequences, `X`. The y-axis at the left side of the graph represents the other sequence, `Y`. Hence, the two sequences in question is the following:

```
X = [A, B, C, A, B, B, A]
Y = [C, B, A, B, A, C]
```

MDA generates the edit graph through the following steps:

1. Line the element of sequence `X` on the x axis. And do for `Y` on the y axis.
2. Make grid and vertex at each point in the grid (x, y), `x in [0, N] and y in [0, M]`. `N` is the length of sequence `X`, `M` is of `Y`
3. Line for `x - y = k`, this line called k-line.
4. Check the points `(i, j)`, where `X[i] = Y[j]`, called match point.
5. Connect vertex `(i - 1, j - 1)` and vertex `(i, j)`, where `(i, j)` is match point, then diagonal edge appears.

Each elements on the figure shows that,
- `Red number and dotted lines`: The red number is the value of k and dotted lines are k-line.
- `Green dots: The match points`, which is the point `(i, j)` where `X[i] == Y[j]`
- `Blue line`: The shortest path from source to sink, which is the path we are going to find finally.

> **Note:** Here, the sequences' start index is 1 not 0, so `X[1] = A`, `Y[1] = C`

We discuss about which path is the shortest from `source` to `sink`. Can move on the edges on the graph. I mean we can move on  the grid, horizontal and vertical edges, and the diagonal edges.

The movements are compatible with the `Edit Scripts`, insert or delete. The word `Edit Scripts` appeared here, as referred at Introduction, SES is Shortest Edit Scripts.

Let's get back on track. On this edit graph, the horizontal movement to vertex `(i, j)` is compatible with the script  `delete at index i from X`, the vertical movement to vertex `(i, j)` is compatible with the script `insert the element of Y at index j to immediately after the element of X at index i`. How about for the diagonal movement?. This movement to vertex `(i, j)` means `X[i] = Y[j]`, so no script needs.

- horizontal movement -> delete
- vertical movement -> insert
- diagonal movement -> no script because both are same.

Next, add cost 1 for non-diagonal movement, because they can be compatible with script. And 0 for diagonal movement, same means no script.

The total cost for the minimum path, exploring from `source` to `sink`, is the same as the length of the Longest Common Subsequence or Shortest Edit Script.

So, LCS/SES problem can be solved by finding the shortest path from `source` to `sink`.

# Myers Algorithm

As mentioned above, the problem of finding a shortest edit script can be reduced to finding a path from `source (0, 0)` to `sink (N, M)` with the fewest number of horizontal and vertical edges. Let `D-path` be a path starting at `source` that has exactly `D` non-diagonal edges, or must move non-diagonally D-times.

For example, A 0-path consists solely of diagonal edges. This means both sequences are completely same.

By a simple induction, D-path must consist of a (D-1)-path followed by a non-diagonal edge and then diagonal edges, which called `snake`. The minimum value of D is 0, both sequences being same. To the contrary, the maximum value of D is N + M because delete all elements from X and insert all elements from Y to X is the worst case edit scripts. For getting D, or the length of SES, running loop from 0 to N + M is enough.

```swift
for D in 0...N + M
```

Next, thinking about, where is the furthest reaching point for D-path on k-line. Like below, moving horizontally from k-line reaches (k+1)-line, moving vertically from k-line reaches (k-1)-line. Red chalky line shows that.

<img src='Images/EditGraph_k_move.png' height="400">

So, threre are several end points of D-path, or D-path can end on several k-line. We need the information to get the next path ((D+1)-path) as mentioned above. In fact, D-path must end on
k-line, where k in { -D, -D + 2, ....., D - 2, D }. This is so simple, starting point, `source` is `(0, 0)` on (k=0)-line. D is the number of non-diagonal edges and non-diagonal movement changes current k-line to (kpm1)-line. Because 0 is even number, if D is even number D-path will end on (even_k)-line, if D is odd number D-path will end on (odd_k)-line.

Searching loop outline will be below.

```swift
for D in 0...N + M {
  for k in stride(from: -D, through: D, by: 2) {
    //Find the end point of the furthest reaching D-path in k-line.
    if furthestReachingX == N && furthestReachingY == M {
      // The D-path is the shortest path
      // D is the length of Shortest Edit Script
      return
    }
  }
}
```

The D-path on k-line can be decomposed into
- a furthest reaching (D-1)-path on (k-1)-line, followed by a horizontal edge, followed by `snake`.
- a furthest reaching (D-1)-path on (k+1)-line, followed by a vertical edge, followed by `snake`.
as discussed above.

The Myers Algorithm key point are these.
- D-path must end on k-line, where k in { -D, -D + 2, ....., D - 2, D }
- The D-path on k-line can be decomposed into two patterns

thanks for these, the number of calculation become less.

```swift
public struct MyersDifferenceAlgorithm<E: Equatable> {
    public static func calculateShortestEditDistance(from fromArray: Array<E>, to toArray: Array<E>) -> Int {
        let fromCount = fromArray.count
        let toCount = toArray.count
        let totalCount = toCount + fromCount
        var furthestReaching = Array(repeating: 0, count: 2 * totalCount + 1)

        let isReachedAtSink: (Int, Int) -> Bool = { x, y in
            return x == fromCount && y == toCount
        }

        let snake: (Int, Int, Int) -> Int = { x, D, k in
            var _x = x
            while _x < fromCount && _x - k < toCount && fromArray[_x] == toArray[_x - k] {
                _x += 1
            }
            return _x
        }

        for D in 0...totalCount {
            for k in stride(from: -D, through: D, by: 2) {
                let index = k + totalCount

                // (x, D, k) => the x position on the k_line where the number of scripts is D
                // scripts means insertion or deletion
                var x = 0
                if D == 0 { }
                    // k == -D, D will be the boundary k_line
                    // when k == -D, moving right on the Edit Graph(is delete script) from k - 1_line where D - 1 is unavailable.
                    // when k == D, moving bottom on the Edit Graph(is insert script) from k + 1_line where D - 1 is unavailable.
                    // furthestReaching x position has higher calculating priority. (x, D - 1, k - 1), (x, D - 1, k + 1)
                else if k == -D || k != D && furthestReaching[index - 1] < furthestReaching[index + 1] {
                    // Getting initial x position
                    // ,using the furthestReaching X position on the k + 1_line where D - 1
                    // ,meaning get (x, D, k) by (x, D - 1, k + 1) + moving bottom + snake
                    // this moving bottom on the edit graph is compatible with insert script
                    x = furthestReaching[index + 1]
                } else {
                    // Getting initial x position
                    // ,using the futrhest X position on the k - 1_line where D - 1
                    // ,meaning get (x, D, k) by (x, D - 1, k - 1) + moving right + snake
                    // this moving right on the edit graph is compatible with delete script
                    x = furthestReaching[index - 1] + 1
                }

                // snake
                // diagonal moving can be performed with 0 cost.
                // `same` script is needed ?
                let _x = snake(x, D, k)

                if isReachedAtSink(_x, _x - k) { return D }
                furthestReaching[index] = _x
            }
        }

        fatalError("Never comes here")
    }
}
```
