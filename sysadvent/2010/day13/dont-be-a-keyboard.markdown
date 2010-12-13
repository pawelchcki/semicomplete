# Don't Be a Keyboard

There are few things that quite irritate me more than when I accidentally take
part in building a habit (or a culture) that treats people like human
keyboards.

Humans are not meant to be buttons for pushing or functions for calling.

What does it mean to not be a human keyboard? Imagine for the moment, that
instead of typing on a keyboard or using a mouse, you had to speak at a person
to perform any task? 

> You: "go to my email"
> You: "show me that first message"
> You: "scroll down a bit"
> You: "scroll down a bit more"
> You: "I want to reply to this email"

This sounds silly, right? Yet, other, very similar situations occur quite often
in business as interactions between employees making requests of each other. In
[2008, SysAdvent day
22](http://sysadvent.blogspot.com/2008/12/day-22-whats-problem.html) reported a
subset of this problem - where people may tell you to implement a solution
rather than telling you what problem they need solved. When Frank (fictional
person) says "install Postgres on that server," he is treating you like a
keyboard. He isn't presenting you with a problem needing solved, he is
telling you to implement a chosen solution. You have a function being called
and a result is expected. What result? You don't know the problem!

Let's ignore, for this situation, situations where it may be correct to accept
input as "install this software."

The social problem with being treated like a keyboard is interesting. In the
great acronym, [PEBKAC](http://en.wikipedia.org/wiki/User_error), who is the
user? I would say, you are the keyboard, and Frank (above) is the user. What happens
if "install postgres on that server" is obeyed correctly, but doesn't solve
Frank's problem? Even though this is instnace, and "Frank" is between the chair
and keyboard (you), you may be blamed for his errors.

Another example of this is if a coworker asks you, rather than asking that
well-publicized dashboard your team maintains, "is mysql down?" If you answer
the question by checking the dashboard and replying with the answer, you are
only training the requestor that you are the answer robot for mysql status. Instead,
you should say "Check out the status here on the dasbhoard" and provide a URL.
If you don't have a dashboard, you dig and ask "What's the problem?"

Humans are creatures of habit. If you reinforce a behavior, it will persist,
and even spread. You don't want to become the company-wide interface to
answering the "is mysql down" question. You don't want to become a keyboard.

You have a options for avoiding turning yourself into a human keyboard, and
solutions will vary by situation and audience. First, you can simply document
common questions and answers. Second, you could (assuming skill/time/energy)
automate answers that can't easily be documented - like creating a dashboard to
answer service health status questions. Third, if you can't automate it, put
requests like these through your ticketing system. Fourth, you can try to train
the user to answer the question without invoking you.

Regarding the ticket system, if common requests require high effort, you can
use features of your ticket system to track the number of these such requests and
also time spent on them. This will help inform the business about the energy
output of your group versus the energy requirements and can help steer hiring
and other goals.

There are usually some red flags that tell me (even if only subconsiously) that
a request is a "human keyboard" one: annoying requests, simple requests from
technical coworkers, strange solution-based requests when you don't have
context, etc. Personally, my signal is usually that a request is annoying.

Do you have users or coworkers who might treat you like a human keyboard? Go
write that FAQ, make that dashboard, or add that ticket flow. You'll end up
with less stress and more happy coworkers and users. The business will end up with
higher quality support, faster turn-around times for simple requests, and better 
ideas about the kinds of things asked of you and your team.
