# Machine Learning: ID3 Decision Trees

AI4R provides an implementation of the ID3 algorithm for building decision trees from examples.

## Introduction

Given a set of classified examples, ID3 produces a tree using information gain and entropy. The resulting rules are easy to interpret and can be turned into Ruby code.

## Marketing Target Example

Suppose you have survey data containing a city, age range and gender and you want to predict whether someone is a marketing target.

```ruby
DATA_LABELS = ['city', 'age_range', 'gender', 'marketing_target']
DATA_SET = [
  ['New York', '<30', 'M', 'Y'],
  ['Chicago', '<30', 'M', 'Y'],
  ['Chicago', '<30', 'F', 'Y'],
  ['New York', '<30', 'M', 'Y'],
  ['New York', '<30', 'M', 'Y'],
  ['Chicago', '[30-50)', 'M', 'Y'],
  ['New York', '[30-50)', 'F', 'N'],
  ['Chicago', '[30-50)', 'F', 'Y'],
  ['New York', '[30-50)', 'F', 'N'],
  ['Chicago', '[50-80]', 'M', 'N'],
  ['New York', '[50-80]', 'F', 'N'],
  ['New York', '[50-80]', 'M', 'N'],
  ['Chicago', '[50-80]', 'M', 'N'],
  ['New York', '[50-80]', 'F', 'N'],
  ['Chicago', '>80', 'F', 'Y']
]

id3 = ID3.new(DATA_SET, DATA_LABELS)
```

The generated rules can be inspected with `id3.get_rules` and evaluated for new examples using `id3.eval`.

## Loading Data from CSV

For larger datasets, load your training data from a CSV file:

```ruby
data = CSV.read('data_set.csv')
data_labels = data.shift
id3 = ID3.new(data, data_labels)
```

## Direct Evaluation

Because `get_rules` returns valid Ruby code you can evaluate it directly for fast classification:

```ruby
id3 = ID3.new(DATA_SET, DATA_LABELS)
age_range = '<30'
city = 'New York'
gender = 'M'
marketing_target = nil
eval id3.get_rules
puts marketing_target  # => 'Y'
```

## Validation and Pruning

Pass a separate validation set when building the tree and call `prune!` to
remove branches that decrease accuracy. You can also limit the depth of the
induction with the `:max_depth` parameter.

```ruby
training = DataSet.new(:data_items => DATA_SET, :data_labels => DATA_LABELS)
validation = DataSet.new(:data_items => VALIDATION_ITEMS,
                         :data_labels => DATA_LABELS)
id3 = ID3.new.set_parameters(:max_depth => 3)
         .build(training, :validation_set => validation)
id3.prune!
```

Further reading: [ID3 Algorithm](http://en.wikipedia.org/wiki/ID3_algorithm) and [Decision Trees](http://en.wikipedia.org/wiki/Decision_tree).

## Tree Visualization

The induced tree can be exported to a nested Ruby hash using `id3.to_h` or to
GraphViz DOT format using `id3.to_graphviz`.

```ruby
id3 = ID3.new(DATA_SET, DATA_LABELS)
dot = id3.to_graphviz
File.write('tree.dot', dot)
```

Running `dot -Tpng tree.dot -o tree.png` will generate an image of the decision
tree.
