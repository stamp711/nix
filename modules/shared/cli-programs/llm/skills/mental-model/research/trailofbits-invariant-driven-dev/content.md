# The call for invariant-driven development

Writing smart contracts requires a higher level of security assurance than most other fields of software engineering. The industry has evolved from simple ERC20 tokens to complex, multi-component DeFi systems that leverage domain-specific algorithms and handle significant monetary value. This evolution has unlocked immense potential but has also introduced an escalating number of hacks.

We need a paradigm shift toward invariant-driven development to drive the industry toward a more secure future. By embedding invariants—key properties that must always hold—into every stage of the software development lifecycle, you can significantly enhance the robustness of your smart contracts.

In this blog post, we’ll explore what invariant-driven development means, why it’s essential, and how you can adopt this approach to elevate your security practices and build more robust smart contracts.

## What are invariants?

At its core, invariant-driven development involves defining and maintaining invariants: statements about a program that must always hold, regardless of its state or execution path. These invariants act as the backbone of a system, ensuring its logical and functional integrity.

In smart contracts, invariants can take many forms depending on the application. For example:

- **ERC20 supply:**An ERC20 invariant is that a user’s balance must never exceed the token’s total supply.
- **Automated market makers (AMMs):**In a system using the- `x * y = k`formula—like Uniswap—the formula acts as an invariant for the swaps, ensuring that this equation remains true after every trade (assuming no fee).
- **Lending protocol:**An invariant of the function computing interest earned over time is that it is an increasing monotonic function (e.g., the return value increases as time increases).

Invariants can generally be categorized into two types:

- **Function-level invariants**often focus on specific computations and typically don’t need to change the state (e.g., the- `pure`or- `view`function in Solidity). For example, the lending invariant described above (the function that computes interest is an increasing monotonic function) can be expressed through a function-level invariant.
- **System-level invariants**span the entire system’s state and transitions, such as ensuring that its assets are always greater than or equal to its liabilities. An example of a system-level invariant is ensuring no user has a token balance greater than the total supply.

If you are familiar with fuzzing or formal verification, you are already familiar with invariants. Yet, as the next section shows, invariants are not limited to these techniques; you can also use them in the context of:

- **Monitoring**, through external tools, watching for transactions that break invariants
- **On-chain invariants**, which are executed directly within the smart contract and act as post-conditions when users interact with the contract
- **Manual reviews**, where the code review focuses on verifying key invariants

If you want to learn more about developing invariants in the context of fuzzing, see see the fuzzing page on our Building Secure Contracts website and our fuzzing workshop.

Security researchers have used invariants to assess contracts for many years; our public reports include invariants that are over six years old, and their usage has been crucial in most of our security reviews. Nowadays, many of our competitors follow our approach, highlighting its efficiency. However, software engineers still barely use invariants despite their success in the security community. This is what we hope will change in the upcoming years.

Invariants are not a one-time consideration—they should guide every step of your smart contracts’ development. Here’s how you can apply them at every step of the process.

### Design the invariants

The earlier you start thinking about and documenting invariants, the more significant their impact on your project. Start by identifying invariants during the initial design of the protocol before any code is written. Ask the following questions:

- **What are the main invariants?**Ask your team to identify the 10 most essential invariants so they can keep them in mind at every stage of the project’s development. If they can’t answer, then dedicate more time to identifying them.
- **How will these invariants be checked?**How invariants are checked will influence the code’s design. For example, invariants that will be monitored require the emission of relevant events, and invariants that will be run on-chain can benefit from specific code isolation.
- **How will these invariants be specified and kept in sync with the code?**Chances are that your specification will evolve as your code and project’s requirements change. Having a process to ensure that they remain in sync will be crucial for the long-term success of the protocol.

This phase requires no special tools—just basic note-taking and documentation. Use this schema as a baseline:

| ID  | Invariant             | Components                     | Testing strategy                                         |
| --- | --------------------- | ------------------------------ | -------------------------------------------------------- |
|     | <English description> | <contracts/functions involved> | <fuzzing, formal verification, unit test, manual review> |

The English description can be as simple as how you describe it verbally. However, a good practice for complex invariants is to describe them through a Hoare Triple-like format (pre-condition, command, post-condition). Despite the formal-sounding name, a Hoare Triple simply captures three key elements:

- Pre-condition: Assumptions about the state/parameters before the actions
- Command: The actions to be tested
- Post-condition: What must be true after the actions

Conceptually, this is the same as following an Arrange, Act, Assert or Given, When, Then design pattern if you’re familiar with them.

For example, the `x * y = k` invariant may be expressed following this schema; see ToB1:

| ID   | Invariants                                                                                                                       | Components                 | Testing Strategy    |
| ---- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ------------------- |
| ToB0 | The balance of any user must never exceed the total supply of the token                                                          | `MyToken`                  | Fuzzing             |
| ToB1 | • If the pool has no fee (_pre-condition_) • Call the swap function (_command_) • `x * y = k` has not changed (_post-condition_) | `MyAMM`                    | Fuzzing             |
| ToB2 | The function computing the interest earned over time is an increasing monotonic function                                         | `Lending.compute_interest` | Formal verification |

If you’re looking for inspiration on creating invariants, you can find a set of predefined invariants in our properties repo.

### Implement and test the invariants

The longest part of the smart contract development lifecycle is development and testing. Here, an iterative process between developing the code, creating and updating the invariant, and general testing will be crucial.

For example, identifying functions-level invariants will help you design the right level of modularity for your codebase, separating the components in a way that makes them easier to test.

During this phase, the tools at your disposal are:

- Fuzzers (e.g., Medusa, Echidna, and Foundry)
- Formal verification tools (e.g., Halmos, Certora, and KEVM)
- Manual review

The invariants can typically be written in Solidity (as shown below) or in a domain-specific language like CVL for the Certora Prover.

// User balance must not exceed the total supply function test_ERC20_userBalanceNotHigherThanSupply() public { assertLte( balanceOf(msg.sender), totalSupply(), "User balance higher than total supply" ); }

As your codebase evolves after deployment, continue testing the invariants on every code change/PRs. CloudExec will help you run your fuzzer continuously in the cloud, while fuzz-utils will convert the fuzzing findings into Foundry unit tests.

The choice of tool will depend on the invariant and the codebase; see our blog post describing when to fuzz versus using formal verification. If some invariants are straightforward enough—or the opposite, too complex to test with tooling—thorough documentation and unit testing will be crucial.

#### On-chain invariants

Some invariants can be part of the on-chain code. These invariants can act as post-conditions of the contract’s execution. Uniswap’s `x * y = k` is an example of such an invariant. On-chain invariants are a powerful tool: they provide strong guarantees and are very effective at preventing hacks.

However, making every invariant part of the on-chain code may not be possible. Some invariants require complex computation (e.g., unbounded loop iteration), which increases the gas cost or the risks of bugs in the invariants themselves. One example of a broken invariant is an issue (TOB-UNI-005) in our Uniswap V3 report that could have allowed a malicious user to drain any Uniswap pool. This issue highlights that on-chain invariants are a double-edged sword, carrying unique benefits and risks. That’s why it’s crucial to identify potential on-chain invariants during the design phase to determine which ones will fit the contracts’ code and apply special care to them.

### Validate the invariants

Having the list of invariants ready for third-party or internal code evaluation (security review, bug contest, or bug bounties) will help security engineers understand the system’s critical parts and focus on the most significant risks. This is an example of where invariant-driven development shines: you can onboard security engineers on your codebase more quickly and better understand code review coverage.

During this phase, you will have the same tools as during the implementation: fuzzers, formal verification tools, and manual review. An example of this approach is our Uniswap V4 report, where we tested 100 invariants through automated techniques (fuzzing, formal methods, and custom static analysis). Each technique was tailored for the right invariant:

For insights into how we created the fuzzing harness for this project, watch our presentation on how we designed invariants for Uniswap V4 next week. The date and time will be announced on X.

### Monitor the invariants

It can be challenging to know which aspects of a system are crucial to monitor. This is another area where the invariant-driven development approach shines: the invariants indicate these aspects.

Solutions like Hexagate and Tenderly let you monitor invariants through events and transaction analysis (note that the invariants must be adapted to follow the tools’ custom APIs). You can also leverage on-chain fuzzers (including Echidna and Medusa) to continuously stress-test the invariants written in Solidity with actual values.

Here, invariants must be part of your incident response strategy. For each invariant to be monitored, you must define the following:

- How to interpret and debug why the invariant is broken
- Who in your organization has the proper knowledge
- What actions are at your disposal (e.g., pausing the system, changing a parameter, upgrading the contracts)

Follow our Incident Response Recommendations to plan accordingly, and consider validating your process by hosting a SEAL wargame to simulate a security incident triggered by a broken invariant.

## Why invariant-driven development is powerful

Most smart contract hacks involve a business logic or domain-specific issue. Developers should safeguard against these issues, and invariant-driven development aims to solve them.

By integrating invariants through the entire development process, you will:

- Immediately detect bugs
- Clarify your protocol’s core assumptions
- Reduce the attack surface
- Streamline code review and monitoring

Ultimately, you will shift your mindset to focus on security as a priority.

Invariant-driven development is not just a technique—it’s a development mindset. It’s about integrating a security approach through development and driving the design’s decision to reduce risks. We hope to see several teams adopt this approach moving forward. If you need help identifying and testing your invariants, contact us.
