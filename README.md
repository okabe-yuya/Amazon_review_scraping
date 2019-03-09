# AmazonReviewSc

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `amazon_review_sc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:amazon_review_sc, "~> 0.1.0"}
  ]
end
```

## how to use??
### first: setup your text file
you put _.txt file top directory
and write target url path in .txt file

example.txt
```
https://example.com/1
https://example.com/2
https://example.com/2
```

target url must top product page, not all review page
and don't add \n last line !!

### second
CLI have argument(boolean)
- true: fetch from all page(make page query and fetch all)
- false: fetch from first page only

this is sample for execute this projects

```

./amazon_review_sc true #fetch from all page
./amazon_review_sc false #fetch from first page only

```
