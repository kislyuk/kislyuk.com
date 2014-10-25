# Ensure: Literate programming in Python

[Literate programming](http://en.wikipedia.org/wiki/Literate_programming) was first defined by Donald Knuth as a programming style where units of code are heavily librarized, and programs are written by describing their logic in English and referencing routines from the libraries.

When Knuth was writing his work, most programming languages had semantics and grammar that made code quite hard to read (TODO: EXAMPLE). When thinking about such a subjective notion, I like to use the term **cognitive overhead** (similar in essence to [cognitive load](http://en.wikipedia.org/wiki/Cognitive_load)) to refer to the work that a programmer must do to reason about the functionality of a unit of code. Because all popular programming languages are based on English, most programmers know English; and the cognitive overhead of comprehending a piece of code after becoming familiar with the progrmamming language is roughly proportional to how close the code is to Knuth's literate description of what the program does.

High-level languages like Python and Ruby have focused quite a bit on adding features that enhance code readability. Many software engineering experts describe such features as "syntactic sugar", often in a faintly dismissive tone. In fact, these features are very important for reducing the cognitive overhead of comprehending the code. At the same time, syntactic sugar has to be combined with an otherwise powerful language; [COBOL](http://en.wikipedia.org/wiki/COBOL) was an early, successful language focused on readability which fell out of use because its feature set was otherwise out of date. Overall, a general-purpose language must handle many things well to be successful - concurrency, package management, error handling, documentation and testing support, standard library contents, and more - but I believe none are more key than readability. And unlike some other features, readability has to be a design principle embedded in the language community, not just something written once by an expert.

Readability is particularly important because of its effect on beginner programmers. It intrinsically lowers the learning curve of a programming language by reducing the cognitive overhead, which accelerates learning. In this century, programming literacy will take the place of plain literacy as the educational frontier. Use of the written programming word will pass from the few (who, given the way many modern programming languages read, might as well have been using Latin) to the many. And languages with the biggest focus on friendliness and readability will have a huge head start in attracting the popularity and resources they need to be successful.

#### New post here?

Ensure hook goes here





