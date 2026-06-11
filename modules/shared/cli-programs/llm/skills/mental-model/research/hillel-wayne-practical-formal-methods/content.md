- tl;dr sec
- Posts
- PLTalk: Practical Formal Methods with Hillel Wayne

# PLTalk: Practical Formal Methods with Hillel Wayne

## Jean Yang, Hongyi Hu, and Hillel Wayne discuss making programming languages/model checking more accessible, give an overview of TLA+ and Alloy, and successfully avoid fisticuffs over unbounded vs bounded analyses

Here are some quick notes I took from an episode of PLTalk on July 17th, 2020, which is a Twitch stream by Jean Yang and Hongyi Hu on making academic-y programming languages research more accessible and hopefully more widely used.

Jean and Hongyi were joined by guest Hillel Wayne, and the overall focus was on model checking in the real world, TLA+, and Alloy.

**Take-aways**

- Formal methods can be used to find design/specification level bugs that can be tricky to find in other ways. So the practical value from an industry perspective is finding these impactful bugs - *sooner*and thus more cheaply, before you have to rearchitect a complex system.
- *Bounded*model checkers only explore state spaces to a certain depth (e.g. only unrolling loops a fixed number, say 4, times), while- *unbounded*tools exhaustively explore a given state space.- *Bounded*tools get harumphs and grumpy fist shaking from academics in their ivory towers, but in practice, can be quite effective.

- Every model checker or solver is heavily optimized for certain problem domains and use cases. Thus, it’s critical to use the right solver for the right problem.
- If Jean were to recommend a single tool in this space for people to learn, it’d be Z3.
- Hillel has a neat 7-part cheatsheet for his workshop in which each one gradually reveals more sections on the same page, so everything students see at a given point in time they already understand and have context before. - By not overwhelming them with a dense page all at once, he’s found they can use it to find what they’re looking for much faster and easier.

**Hillel’s Formal Methods Origin Story**

Hillel was previously a developer at an edTech company that was experiencing a series of high impact, tough distributed systems/concurrency bugs.

He spent a few days rabbit holing into TLA+ and thought that it would be useful for the challenges they were facing at work.

- A light switched in the CTO’s head when Hillel came in with a TLA+ spec that found the bug.
- TLA+ is basically testable pseudocode - you describe at a high level how your system should behave and the properties you want, then it’ll brute force the state space to see if those properties are satisifed by your system.
- Particularly designed for concurrency and distributed systems.

_How did you get into doing this full time?_

- At the time, formal methods was focused on niche uses - mission critical software, etc.
- Most literature assumed you were already bought in, made it harder for outside people to get involved.
- What if there was learning material that made it easier to learn? So he wrote LearnTLA - “if I wrote a book, I can probably get a higher salary for my next job.”
- Someone reached out and asked if he did TLA+ consulting, then David Beasley encouraged him to do a workshop.

**Alloy**

Alloy is another tool in the same space. It has a REPL, which drew everyone to it. He bought the book, read it in 2 sittings, emailed the author, telling him how much he loved the book. Now he’s on the board and writing the new official docs for Alloy.

Jean did her PhD at MIT, her office was 3 down from Daniel Jackson. One thing they wondered all of the time - who was going to use Alloy in the real world?

Alloy is a bounded model checker, which means it explores the state space, if there’s a loop, it’ll unroll it `N` times where `N` is a fixed number, it won’t explore every single loop iteration. Other professors would show up - what if a bug shows up in the `N+1`th loop? Many conversations about the trade-offs.

There are 2 major core constraints in Alloy that have shaped it:

- It should be much easier to teach. The entire grammar is the same length as the JSON grammer.
- Every single expressible statement should be model-checkable. - In TLA+ you can write a number of expressions that are valid in the language but we don’t know how to model check them.

**Why is this important from an industry perspective?**

A lot of bugs aren’t just implementation bugs, like an off-by-one error in a loop. They’re bugs that are _locally_ correct everywhere but _globally_ incorrect. The features interact in a way that causes an issue. This could be due to a problem like incomplete requirements.

A canonical example: if you have do not reply and call forwarding, and you have someone call forward to a do not reply, how should that be handled?

The value of formal methods is finding these fundamental design requirements and interactions quickly without having to build the system first.

In sum, this saves a lot of money.

Jean’s background: let’s verify the implementation of things.

Hongyi: really we’re discussing two types of problems:

- You haven’t built the system yet, you’ve thought about the design and you can apply this tool to find problems with how you designed it.
- Empirically I have an existing system, let me verify what it actually is.

Different levels of abstraction require different tools.

**Alloy Demo**

29:20 Hillel starts an Alloy demo. This section continues the relevant section as it was present. See here for a gist Hillel shares in the middle.

_Finding good, concrete examples is very hard and often undervalued. _

In Alloy, everything is basically a signature, an “atom.”

- Things or relations between things.

If you don’t give any requirements, Alloy will generate up to 4 of each element.

Is there a resource that is allowed to see some resource and a second user that is not allowed to see any resource?

```
sig User {}
sig Resource {
  , allow: set User
}
run {
  some disj u1, u2: User |
    u1 in Resource.allow and u2 not in Resource.allow
}
```

A _predicate_ is a True or False boolean function.

```
pred can_access[u: User, r: Resource] {
  u in r.allow
}
```

A user can access a resource if a user is in its Resource `allow` list.

At what point would you create a model like this?

Could be before building a system, as a post mortem, or for legacy system. Lots of potential times.

```
run {
  some disj u1, u2: User |
    some disj r1, r2: Resource |
      u1.can_access[r1] and u2.can_access[r2]
}
```

Now add a property: resources can have subresources, and resources may or may not have a parent.

- If you can access a parent resource you should be able to access its subresource.
- `lone`means- `<= 1`, a resource may or may not have a parent

```
sig Resource {
  , allow: set User
  , parent: lone Resource
}
run { some parent }
```

Alloy shows us an example of a node being its own parent, which is probably not something we want.

```
fact "No resource can be its own parent" {
  no iden & parent
}
```

However, a subresource can still be the parent of its parent, which is also bad.

37min - Hillel opens the Alloy REPL. You can type `parent` or `parent.parent` to see those values, or `^parent` to get the transitive closure of the Resource’s hiearchy.

Updating the fact from before:

```
fact "No resource can be its own ancestor" {
  no iden & ^parent
}
```

Note that the `facts` are axioms, not predicates.

- An - **axiom**or- **fact**is something that always be true, if it becomes false, then something horrible is wrong. Like for this example, if a resource is its own parent, then their database is in a bad state. We don’t want this to ever be possible.
- A - **predicate**may or may not be true, and we want to either assume its true or force it to be true.

_If a predicate property is false, then something is wrong with our design. If an axiom is false then something is wrong with the universe. We throw out every model where the axiom is wrong._

Jean: axioms are your building blocks for building truths off of, predicates are your structures. All predicates need to be buildable from your axioms.

Predicates are things you want to conditionally assume and test.

`r.~parent` - you’re flipping the relation, getting every child.

```
assert parent_implies_child {
  --- if you can access a parent, you can access its child
  all u: User, r: Resource |
    u.can_access[r] =>
      all c: r.~parent |
        u.can_access[c]
}
```

**Model finding** is generating examples where certain predicates are true so you can see what they look like.

**Model checking** is trying to find cases where the model is false and giving you an example.

```
pred can_access[u: User, r: Resource] {
  u in r.allow or u r.parent.allow
}
check parent_implies_child
```

This does _not_ work because you need to check transitively (shoutout Qubyte for finding it).

If you change this to finding the transitive closure of `parent` (adding the `^`), then Alloy can no longer find a counter example.

```
pred can_access[u: User, r: Resource] {
  u in r.allow or u r.^parent.allow
}
```

_When it comes to complicated design bugs, they often show up in small models, which is one of the reasons bounded model checking is so unreasonably effective._

Jean: One controversial thing about Alloy is its bounded nature. How do you know you’ll go deep enough to find important bugs?

_Soundness_: if there’s a bug, are we guaranteed to find it?

Because Alloy is bounded, it’s not sound, which is very controversial in academia.

“Small Scope Hypothesis” - if you’re going to find something wrong, you’ll find it wrong pretty quickly, you don’t need to explore every edge. If you have a bug, it’ll show up in 3 loop iterations, don’t have to wait until the 1000’th. Paper: Evaluating the “Small Scope Hypothesis”

**Errors in Specifications vs Implementations**

_Question for Hongyi: for a practitioner who’s implementing access controls and other systems like this in the real world, how often do you find issues at the spec vs implementation level?_

It depends on the area you’re working in. His work more recently has been start-ups, before that was more industry/academic hybrid. If you’re looking at a company building a user-facing product, he’s interested in trying out this at the design phase, e.g. when a PM wants to build a new feature or product, here’s what we’re thinking.

Having a tool to help you explore and think about the types of issues that crop up can be helpful.

Usually at that time you don’t have a spec that’s set in stone. “We’re thinking through some different options about how the features could work.”

Privacy is very tricky, dependent on user expectations, culture of the population, dependent on the laws of the jurisdiction. What one person might consider a privacy violation is OK to other types of users. Having a tool that can generate these various cases could be useful in giving you prompts to think through earlier in the design phase.

_How often do you have bugs that are a result of the spec being unknown or the transitive case missing vs encryption had a bug in it, some level of infra bug, etc.?_

Product is probably where it gets the most complex, depending on the stage of the company. Eventually you get incredibly complicated code in which the behavior is not well known or understood. The product has grown organically over time.

When you’re talking about software architecture, e.g. access control policies in AWS or Google Cloud, that’s probably more straightforward for a tool like Alloy.

**Having Developers Write Specs**

_How easy is it to get devs to write specs that are not automatically generated from code and how much do they trust the output?_

Hillel - like pulling teeth. It has a huge time payoff, but you need to put in the initial upfront time. He’s found it more likely to happen when there is manager buy-in.

Hongyi - quite hard. Usually they just have other priorities and not enough time.

Hillel - a lot of it is driven by advocates, they read about it, play with it, then want to learn more. Usually when companies approach him they already have engineers who want to do it.

So he sees it less as convincing companies who are not at all interested in it than nudging companies that are already excited about formal methods.

**How Hillel Finds Interested Companies**

_How do you find the right companies?_

It’s easier to get word of mouth and to have people find you than it is to do outbound. That’s one of the reasons he did the journalism and history work, writing – it gives him enough reach that people start to hear about it, if they get interested then they approach him.

Many of the companies he’s worked with have been cloud infrastructure providers.

_Do you see any commonalities in the types of problems these companies apply Alloy to? e.g. access control policies, that may infra configuration won’t cause stability issues._

Hillel - Not so much. Usually at the end of his workshops they spend a day thinking about the company’s exact problems and work on writing a spec together. That helps make it worthwhile to them and cementing why they’re using it.

**Could you use graph algorithms?**

_Do you think it is feasible to offload some of the state space exploration in TLA+ if you export a spec into a dot file, parse it, and check your invariants on that graph?_

Hillel: Yes, he’s done this with a graph tool, dropping a massive graph into it, find shortest routes, etc. Gefi.

**How do you choose a first issue to demonstrate Alloy on?**

Hillel usually has a few self-contained examples to demonstrate how formal methods works in general.

You can’t necessarily have an example for every use case a company has, but you can give them illustrative examples and they can extrapolate.

**Alloy “facts” vs the real world**

_Real-world code might have to deal with a database that somehow became broken. How do you decide what to turn into “facts” when the world is not trustworthy?_

Facts are used to rule out stuff that is uninteresting. Formal methods only works for proving something correct assuming your core assumptions are not violated. If those are violated, everything goes out the window, you have to accept this and be humble about it.

**TLA+ vs Alloy**

_What problems did you encounter with Alloy that you couldn’t solve as easily with TLA+?_

Alloy is a lot better for a few things. For TLA+ model checking the primary tool is a brute force model checker, for Alloy it’s converted to a big SAT problem, which makes it fast to check.

Alloy tends to be better for things that are like graphs because it has great transitive closure and relationship operators.

Jean - Every model checker or solver is really fast for certain types of structures. Every solver is heavily optimized for certain sets of things. Jean has had Alloy be really slow for some problems. **Using the right solver for the right problem is important.** Some are good for objects, strings, or numbers, but not others.

If you’re interested in this broader space, Hillel has a project called “Let’s Prove Left-Pad” where he asks people to submit formally proven correct versions of left-pad. It has a lot of the creators of these tools writing things, e.g. Idris, Liquid Haskell. You have to explain in detail how your tool works and your solution.

**Hillel’s Workshop**

Hillel is running a workshop in 2 weeks on TLA+, optimized for people having their company pay for it.

**Things formal methods are not good at?**

Hillel wrote a blog post about this.

- If there’s a low cost of error - easy to isolate, won’t cause many issues, it’s not worth throwing all of these formal tools at the problem.
- Data munging between formats, these are not great tools for that.
- Probabilistic stuff.
- Largest category - augmentations. Instead of writing programs that automate something, writing programs that augment a human to do something better. If you’re blurring the line between what the computer vs human doing it tends not to be as effective, the human can self-correct the system in a way that makes formal method less useful.

**Writing Specs Based on Existing Code**

_Do you always write the spec from the conceptual view of the domain, or have you ever translated code to alloy? Like a database structure or ORM-like code._

Yes, “Finding bugs without running or even looking at code” Strangeloop 2019 talk by Jay Parlar on Alloy gave a talk on this.

Going from a spec to implementation code is very hard. Nadia is a major figure in program synthesis so she probably has neat stuff to say about this. But a commercial level, this is not cost effective.

You can use the model to generate property tests, but you have to customize that per language you’re using. Using the tool is scoped to one language and problem domain, not a big push to make general turning tests to specs tool.

**Could you use TLA+ for type systems?**

Jean - you want non bounded things for type systems usually because your type system is giving you guarantees, so you want exhaustive testing.

Every tool is created with a specific use case in mind. TLA+ was created thinking about distributed systems problems, Alloy was created for large scale requirement documentation. These are different problems then when you’re designing a type system. Many formal methods tools aren’t a good fit for compiler-type domains, which is why people use tools like Coq.

_Would it be useful for prototyping though?_

Jean - I’d use a randomized tool for prototyping probably not bounded.

Hillel - many specs written with theorem provers are also bounded, because they have to terminate, they’ll have a fuel counter.

Jean - the search may be bounded but within that space it may be unbounded.

_Related to this, I have wondered if we can use model checking to help be sure that the types we come up with (especially dependent types) are modelling the problem we think they are._

Hillel - I’m a big believer in the “rising tides lifts all boats.” If we can make this easier then more people will use it. Many advances in formal verification happened when Microsoft open sourced Z3 and made it nice and easy to use.

Jean - If I had to recommend a single tool for people to learn to use, it’d probably be Z3. Most papers she likes has Z3 running in the back somewhere.

Jean - The SAT boolean satisfiability problem: is there a satisfying assignment? Most modern automated things are compiled down to that problem. You can do pretty powerful reasoning about models that way. An SMT solver (satisfiability modulo theories) - people have built many abstractions on top of SAT - theory of integers, theory of lists, objects, strings, etc.

**What challenges have you observed in teaching people Alloy?**

- Teaching people how to specify.
- Learning the specific tool.

One of the reasons Hillel likes Alloy is it’s much more user friendly than a number of other tools.

Many of the challenges are getting people to think about specs.

The first barrier most people hit if they don’t have a math background is the implication operator. So he spends a lot of time optimizing how you teach just that.

A lot of the people Hillel teaches don’t have a math background.

Usually Hillel sends out a math worksheet to attendees the week before, has them fill it out, then reviews it and customizes the math section based on that.

Learning implication is absolutely essential, which is why it’s the first major roadblock.

He also spends a lot of time writing optimizations - _progressive cheatsheets_. See 1:20:24 for a really neat example.

- It’s actually 7 cheatsheets. Attendees first get an initial cheatsheet, then they get the next one that fills out a few sections on the same page.
- Hillel has found that attendees spend a lot less time trying to find info on the sheet and trying to find out what’s useful to them, because everything there is stuff they’re already learned, and they have an intuition from past experiences about where things are laid out.

**Next PLTalk**

Jean and Hongyi will be joined by Nadia Polikarpova, an assistant professor at UC San Diego who has done interesting work in program synthesis.

Recent paper: Liquid Information Flow Control
