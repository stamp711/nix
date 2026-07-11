# The pragmatic magic of semi-formal methods

So, you’re building a software system that has to work, period. It’s supposed to be a reliable, secure, and maybe even a mission-critical system. No pressure, right? Traditional software engineering practices - code reviews, automated testing, and fuzzing - have carried you this far, but you worry that they might not be powerful enough for this new system. You crave confidence in your code, but you don’t know how to achieve it. You’ve heard whispers of formal methods – the mathematical spell that guarantees system correctness – but every time you look deeper, your soul quietly leaves your body. TLA+? P (the programming framework)? It all starts to feel like you’re getting a PhD when all you want to do is merge a pull request.

What if there’s another way to feel more confident? To secure your system without diving headfirst into the deep end? What if you could increase the reliability and security of your systems without needing to learn a new programming language to define a lemma? This blog post welcomes you to the secret shop of semi-formal methods, where you buy magical armor piecemeal to buff up youbz methods, but we care deeply about making software reliable, uding whatever tools it takes, and we do use semi-formal methods in our own internal development.

Do you prefer visuals over text? Watch the talk. Seriously, it’s delightful.

## Formal methods and where you find them

Remember when I said we won’t dive into the deep end? Well…. that was technically correct. We won’t dive in, but let’s go stand on the edge and gaze into the abyss.

Formal methods are mathematical techniques to prove that your software does what it’s supposed to do. You write a formal specification to mathematically model your complex system, in a language usually different from the implementation language. You also define system invariants that the specified model must uphold. And then you use some type of formal proof method (e.g. proof assistants, model checkers, etc.) to verify that your specification does indeed satisfy the desired properties. Formal methods offer the most rigorous form of verification, ensuring that your system model meets the specified design. No maybes. Just cold, hard math.

Let’s write a sorting function - insertion sort.

```
function sort(list):
  if list is empty: return list
  else: return insert(first item, sort(rest of the list))
```

Before you even begin to think about the invariants of the sorting function, you must spend time defining the entities in the function. What is the datatype of the items in the list? Can it store multiple datatypes? Is the function sorting in increasing or decreasing order? What does increasing or decreasing order mean for my datatype(s)?

Once you have answers to these questions, you move on to the invariants.

- The output is a permutation of the input.
- The items in the output appear in sorted order.
- The algorithm should terminate for all inputs.

To verify this formally, you’d write a specification with the above invariants and definitions for `sorted order` and `a permutation` to go with the specification. This will then be checked by a verifier that proves your specification satisfies the invariants.

Here’s the thing though: that’s a simple recursive sort. Your system isn’t a few lines of code to sort integers. It’s not even a crypto library, secure device driver, or closed-loop navigation software for rockets. It’s distributed! It has multiple nodes and microservices! And it talks to the outside world! Now you’re writing hundreds of definitions and lemmas just to prove your system’s behavior.

Formal methods prove that the specification supports your system invariants. But, in practice it’s not easy to guarantee that the specification correctly models the implemented system. If your specification is correct and the implementation is in sync with it, formal methods are foolproof. But they are hard. And rigid. And expensive to begin with. Which is why you’ll find them in high-stakes environments where failure means lost lives or lost billions.

But in the everyday software industry, where things move fast, the humble code review is the dominant mode of verification. You convince a skeptical co-worker to review your code. They squint at the PR, nitpick the formatting, and look for minor bugs. It’s social. It’s human. It runs on general trust in your fellow programmers not to accidentally blow up production. So, your code is only as strong as the reviewer.

Formal verification is very good at providing correctness guarantees, but it does not scale well for complex projects. Code reviews, while highly scalable, are just not rigorous enough for your system. Don’t you wish for a happy medium? Something a little more confidence-inspiring than a quick LGTM from your reviewer?

## Enter: semi-formal methods

Semi-formal methods borrow the structure and mathematical language of formal methods and embed them within the code directly. Think of it as logic-driven development, where you lay out the logical structure of the system and check that your implementation still follows the logical structure. Semi-formal methods sit in between dystopia and utopia (It’s up to you to decide which one’s which). They are a lot more realistic in terms of correctness guarantees and cost.

Here’s the big idea:

- Define your system entities and actors.
- Write down your assumptions.
- State your system requirements.
- Describe your code obligations.
- Enforce them.

### A real-world example

Let’s write a semi-formal proof for a system with the constraint: “An authorized user can view the report”. Using the big idea above, there are 4 main steps to follow before diving into the code.

- Definitions - System entities and actors
- An authorized user is a real human who has completed their SSO and holds a valid session.
- The browser origin must be trusted to serve web requests.

- Assumptions - What you believe to be true
- Correct origin policy.
- Correct headers will be set.
- The SSO cookies are secure and have not been leaked.

- Requirements
- Only authorized users can view the report.

- Obligations - What the code must do
- No information is leaked between requests.

Implementing this system in Rust:

When using semi-formal proof methods, the general obligations of the code are pinned as comments with a review tag. If and when a new developer touches this part of the code, they will update the comment to reflect the change and tag it as unreviewed before approval.

But what if the new developer changes the order of the Origin and Host headers to alphabetize the code? It introduces a bug! The Origin and Host headers go into the wrong variables.

### Strongly typed languages

Catching the bug above might be really really difficult in a traditional code review. But when you make friends with strongly typed languages, you can alleviate a lot of problems by benefiting from their behavior.

You can create two new wrapper types, one for Host, and one for Origin, to ensure that one cannot be used in place of the other. If the new developer now swaps the order of the headers, the Rust compiler will not let it pass. It just won’t compile. (You should seriously consider using strongly typed languages. They are great! )

If you make the compiler your ally, you can enforce types on your variables, restrict access to taking actions on certain objects, and more. You can directly embed the desired system behavior into code without reading a book on lemmas.

Now you’ve created a codebase where:

- Reasoning is explicit.
- Assumptions are documented.
- Types are enforced and encode obligations.
- Changes must be proved and reviewed.

Isn’t this great!

## Use semi-formal methods

So far, you’ve been torn between formal proofs and “trust me bro” to verify your code. But you shouldn’t have to pick between the two. You can use semi-formal methods alongside your current process be it formal verification or code reviews.

Semi-formal methods give you:

- More confidence in your code.
- Less pain than formal methods.
- A clear understanding of your system.
- Better documentation.
- A friendly onboarding process for new members.

It does require more work – 2x-3x more work, but sometimes it’s worthwhile to spend that time to ensure reliability. You can start with using semi-formal methods on the components that sit between the outside world and the juicy innards of your system. You can use strongly typed languages. You can start with one definition and obligation and keep layering. You really don’t have to abandon your current stack or learn formal verification tooling. Just start small. Just buy a blazer!

If you reached the end, you should watch the talk. It’s smart, it has examples, and the jokes are better. Treat yourself.
