**[Update]\*** I have made several additions to the original post based on the excellent feedback I have received. The new recommendations are marked out in italics with credits at the end of the article.\*

Microservice architecture is a widely adopted practice now in the software engineering world. Organizations that adopt this architectural style find themselves dealing with the added complexity of distributed failures (over and above the complexities of implementing business logic).

The fallacies of distributed computing are well documented, but subtle to detect. As a result, building large scale, reliable distributed systems architectures is a hard problem. As a corollary, code that looks fine in a non-distributed system can become a huge problem the moment we introduce the complexity of a network interaction to it.

After encountering failure patterns in production code for several years and having root caused them to various bits of code, I (like many others) have come to identify some of the more commonly occurring failure patterns. These vary slightly across companies and language stacks (depending on the maturity of the internal infrastructure and tooling), but one or more of these are very often cause of production issues.

Here are some code review guidelines that serve as my base checklist for reviewing code relating to inter-system communication in a distributed environment. Not all of them apply all the time, but they are all pretty basic problems, so I find it useful and comforting to mechanically go down this list, flagging missing items for further discussion. It is, in that sense, a dumb checklist that you would likely ALWAYS want to be followed.

## When invoking remote systems

### What happens when remote system fails?

No matter how much care a system is designed with, it will fail at some point- that’s a fact on running software in production. It may fail due to a bug, or some infrastructure issues, or due to sudden spike in traffic, or with the slow decay of neglect, but fail it will. How the callers handle this failure will determine the resilience and robustness of the overall architecture.

- **Define a path for error handling**: There must be explicitly defined paths in the code for error handling instead of just letting your system explode in the end users face. Whether it is a well designed error page, an exception log with an error metric, or a circuit breaker with a fallback mechanism, errors must be handled explicitly.
- **Have a plan for recovery**: Consider every single remote interaction in your code, and figure out what we need to do to recover the work which was interrupted. Does our workflow need to be stateful so that it be triggered from the point of failure? Do we publish all failed payloads to a retry queue/DB table and retry them whenever the remote system comes back up? Do we have a script to compare the databases of two system and bring them in sync somehow? An explicit and preferably systemic plan for recovery should be implemented and deployed before the actual code is deployed.

### What happens when the remote system slows down?

This is even more insidious than outright failure because we do not know whether the remote system is working or not. The following things should always be checked to handle this scenario. _Some of these concerns can be addressed transparent to application code if we are using Service Mesh technologies like Istio. Even so, we should make sure that they are being taken care of, regardless of the how_.

- **Always set timeouts on remote system calls**: This includes timeouts on remote API calls, event publishing and database calls. I find this simple flaw in so much code that it is shocking and yet-not-unexpectd at the same time. Check if finite and reasonable timeouts are being set for all remote system in invocations to avoid wasting resources in waiting should the remote system become unresponsive for some reason.
- **Retry on timeout**: Network and systems are unreliable and retries are an absolute must for system resilience. Having retries will usually eliminate a lot of the “blips” in system-to-system interaction.- _If possible, use some sort of backoff in your retries (fixed, exponential). Adding a little jitter to the retry mechanism can give some breathing room to the called system if it is under load and may lead to better success rate_- *.*The flip side of retries is idempotency, which we will cover later in this article.
- **Use circuit breaker**: There aren’t a lot of implementations that come pre-packaged with this functionality but I have seen companies writing their own wrappers internally. If you have this choice, definitely exercise it. If you don’t, consider investing in building it. Having a well-defined framework for defining fallbacks in case of error sets a good precedent
- **Don’t handle timeouts like a failure**– timeouts are not failures but indeterminate scenarios, and should be handled in a manner which supports resolution of the indeterminacy. We should build explicit resolution mechanisms that will allow the systems to get into sync for cases where timeouts occurred. This could range from simple reconciliation scripts to stateful workflows to dead letter queues and more.
- **Don’t invoke remote systems inside transactions**–- _When the remote system slows down, you will end up holding on to your database connection for longer, and this can rapidly lead to running out of database connections and therefore outage for your own system._

**Use smart batching : **If you are working with lots of data, make batch remote calls (API calls, DB reads) instead on one-by-one to remove the network overhead. But remember that the large the batch size, the greater the overall latency and greater the unit of work which can fail. So optimize batch sizes for performance as well as failure tolerance.

### When building a system others will invoke

- **All APIs MUST be idempotent**: This is the flip side of retrying API timeouts. Your callers can only retry if your APIs are safe to retry and do not cause unexpected side effects. By APIs I mean both synchronous APIs and any messaging interfaces – client may publish the same message twice (or the broker may deliver it twice).
- **Define response time and throughput SLAs explicitly and code to adhere to them**: In distributed systems, it is far better to fail fast than let your callers wait. Admittedly throughput SLAs are hard to implement (distributed rate limiting being a hard problem to solve by itself), but we should be cognizant of our SLAs and provision for failing the calls proactively if we are going over it. Another import aspect of this is knowing the response times your downstream systems so that you can determine what is the fastest your system can be.
- **Define and limit batch APIs**: If exposing batch APIs, maximum batch sizes should be explicitly defined and limited by the SLA we want to promise. This is a corollary to honouring SLAs.
- **Think about Observability up-front**: Observability means having the ability to analyze the behaviour of a system without having to look at its insides. Think upfront about what metrics should you gather about your system and what data you should gather that will enable you to answer previously unasked questions. Then instrument the systems to get this data. A powerful mechanism for doing this is to identify the domain models of your system and publishing events every time an event happens in the domain (e.g. request id 123 received, response for request 123 returned – notice how these two “domain” events can be used to derive a new metric called “response time”. Raw data >> pre-decided aggregations).

### General guidelines

- **Cache aggressively**: The network is fickle, so cache as much as you can as close to the usage of the data as you can. Of course, your caching mechanism may also be remote (e.g. Redis server running on a separate machine), but at least you will bring the data into your domain of control and reduce the load on other systems.
- **Consider unit of failure**: If an API or a message represents multiple units of work (batch), what is the unit of failure? Should the whole payload fail all once or can individual units succeed or fail independently. Does the API respond with success or failure code in case of partial success?
- **Isolate external domain objects at the edge of the system**: This is another one I have seen cause a lot of trouble over the long term. We should not allows domain objects of other systems be used all over our system in the name of reuse. This couples our systems to the other system’s modelling of the entity and we end up with a lot of refactoring every time the other system changes. We should always build our own representation of the entity and transform external payloads to this schema , which we then use inside our system.

### Security

- **Sanitize input at every edge**- _: In a distributed environment, any part of the system may be compromised (from a security standpoint) or buggy. Hence every system mist take individual care to sanitize its input at the edge instead of assuming that it will get clean/safe input._
- **Never commit credentials**- _: Credentials (database username/password or API keys) should NEVER be committed to. code repository. This is an extremely common practice that is very hard to get rid of. Credential must always be loaded into the system runtime from an external, preferably secure storage_.

I hope you find these guidelines useful in reducing the most commonly found mistakes in distributed systems code. I would to hear if you have some other considerations that you find simple to apply but very effective – we can add them here!

_Thanks for your suggestions!_

- Mayank Joshi for his note on exponential backoffs in retries.
- Manjit Karve for the suggestions on security.
- Sumit Satnalika for recommendation on keeping remote invocations outside transactions.
- Raja Nagendra Kumar for pointing out that service mesh technologies like Istio can take care of some things like retries, timeouts, and circuit breakers.

Read Next – Design review checklist for distributed systems
