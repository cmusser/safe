# Overview
Safe is a Mac OS X menubar application that makes it easy to use many strong passwords, store them securely and access them with a master password.

Passwords are an imperfect way of securing computer systems, but they are in widespread use. The common wisdom is that each login credential should have a unique, hard-to-guess password. The reality is that it's hard to remember lots of obscure passwords, much less accurately type them in. The problem is acute for people, like sysadmins, who needs lots of credentials all day long. Wouldn't it be nice if you could quickly look up credentials and paste passwords into form fields or shell prompts? Safe does this.

# Usage
Everything about Safe is designed to be maximally convenient for people who use passwords all the time. The application is shown or hidden via the hot key Ctrl-` (sort of like Spotlight). It autocompletes the names of credentials, so you can recall them easily. Once you choose one, it copies the password into the clipboard and disappears, returning focus back to the application that needed the password. If you need to use the password again and something else is in the clipboard, just quickly show and hid Safe. Doing this reinserts the last password into the clipboard.

Management is easy too: you can create, modify, and delete credentials, and organize them into groups, perhaps one for work and another for personal use. When editing or creating a credential, Safe can generate a password for you, or accept one you've placed in the clipboard. At no time is the password visible, nor is the data stored on disk in the clear. Safe uses strong cryptography: NaCl for encryption and SCrypt to make the master passwords infeasible to derive.

# Roll Your Own?
Hey, can't you just use one of the commercial offerings, maybe one of the web-based ones? You could. I didn't. I started the project before I knew about those because I'm too lazy and hermitlike to research these things beforehand. I did perform a belated and incomplete survey of other password managers. Well, I __had__ to use one at work, which shall remain nameless, but whose name ended in Pass. Conclusion: I'm glad I wrote my own. The UI of *Pass is clearly a product of the the Make Things Ugly and Difficult Corporation. I don't know what their security is like either, although it's likely they're not idiots, or careless. I'm not afraid of cloud based password storage (I'd like to add it to Safe eventually), but I'd prefer to start small, build from known good security primitives and keep it open for the sake of auditing by actual qualified security experts. Plus, I have a bad case of "Not Invented Here."

# History
The project existed in an earlier form, a suite of UNIX command line programs named "pw", written in Python. This was a huge improvement over no password management at all, but after using it for a while, it still didn't seem convenient enough. You have to keep a terminal window around and switch to it when you want a password. For Mac OS X users, Safe removes this annoyance. "pw" is still available, however, and it uses the same credential files.

# Structure
The aforementioned "pw" suite was a nicely structured set of Python programs that had thoughtful object orientation and other evidence of competent design. I did iOS development professionally for a while, so one would assume that Safe would exhibit similar finesse. It doesn't, really. It's basically an AppDelegate class file with a bunch of callback functions that correspond to all the widgets on the screen. Cocoa bindings are used, sort of half-assedly, where I could get them to work. I had to override a couple of standard classes in minor ways to get certain features to work. The lone O-O aspect is the part that abstracts access to the encrypted credential store. The rationale is that this was not UI-related and made sense to be elsewhere. Also, remote resources might be supported in the future, so some thought into an interface seemed like a good idea. Why the bare-minimum design effort? Because Safe really isn't all that complicated, and I was more interested in the end result, not in the underlying structure of the code.

# Security
I am confident in Safe's on-disk security and the common-sense aspects of its design. It always persists the credential store in encrypted from, and I trust the components used for encryption and key derivation. If your computer is stolen, the thieves aren't going to get your passwords. It never displays password on the screen, so over-the-shoulder snoopers are thwarted. And of course the program's primary feature: the ease with which you can create as many unique passwords as needed--increases your security.

I'm less sure about the security of the running process. While it's running, Safe has the data in memory unencrypted. If the program dumped core, the data might be be available in the resulting core file. Also, if someone attached to the running process with a debugger, they might get it there too. There are possible mitigations for these scenarios: the program could create a temporary key while running, and re-encrypt the data. That might make it more difficult to catch the program with its pants down--with the data in the clear. The clipboard is another potential data leak, given the unknown-to-me security of the Mac OS X Pasteboard. Zapping the clipboard after an interval might be worthwhile paranoia. Finally, if a keystroke logger is installed, you're toast, because observers would be able to capture the master password.

# Acknowledgements
This project made use of a lot of good information and code from other people. Inventing your own security primitives is insane, so of course I used libraries with bona fide crypto. But I also borrowed code for other features too. This is a complete list:

- NaCl: the symmetric key cipher, used for encrypting the data
- SCrypt: the key derivation function, which turns user-supplied master passwords into robust encryption keys
- NAChloride: the Objective-C wrapper for NaCl and SCrypt
- NCRAutoCompleteTextView: the central UI element, which allows easy lookup of credentials by name
- DDHotKey: the global hot key functionality that allows keyboard based hide/show no matter what application has focus
- CocoaPods: allows easy of additional components; this project uses NAChloride and libsodium.
- StackOverflow, CocoaDevCentral, NSHipster, etc.: snippets and answers too numerous to count
- Apple documentation: Conceptual and API reference documentation

# Branding
The project started out as an afternoon lark and the initial problem to solve was: "how do you make a menubar application, anyway?" So its original name, which stuck throughout development was "PWMenu". That's the boring but true "origin story". Obscure references seem to be in vogue for project names, but I think they're lame. so I decided on "Safe". It's short and makes sense. I could have used my project name to let you know that I know that Hank Williams Jr's middle name is "Bocephus". But I could just tell you that directly.

# Future Directions
Right now the program more or less works like I want it. But contributions are welcome and if you want to be a pal, let me know.

One feature would the ability to store the passwords in the cloud. This involves changes to Safe itself, and obviously some kind of backend. Also, some of the process vulnerabilities detailed above need some thought. And there may be bugs and things I hadn't thought of. The application could be ported to Swift, although I'm not sure of the effort needed or benefit derived from doing so.

# License
GNU GPLv2
