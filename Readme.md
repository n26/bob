# Bob 👷

Bob is an extendable [Slack](https://slack.com/) bot written in Swift used to communicate with [TravisCI](https://travis-ci.com/) and [GitHub](https://github.com/) APIs. It's used to perform tasks of repetitive nature that cannot be fully automatized, such as creating release candidates for the App Store.

Simply send a message to Bob on Slack, and it will do the job for you.

## Commands
Bob operates using commands. It comes with a couple of customizable commands, but new ones can easily be created. See [creating custom commands](#creating-custom-commands) for more information.

 All commands are invoked by typing in `{name} parameters`. 
<br>For example: <br>
```
build staging
```
could trigger a job on Travis that would create a build with `staging` configuration and distribute it to testers.
<br>
To see how a command should be used, type `{name} usage`

### Hello

A dumy command that can be used to check if Bob is running. Simply say `hello` to Bob, and it will greet you back.

### Version
You can see which version of Bob is currently running by typing `version`

### Travis Script
`TravisScriptCommand` is a configurable command that triggers a job on Travis and executes a script there. The command can have multiple targets that can be specified at runtime.
<br>The script to run for each target is specified when the command is instantiated.
<br>For example:<br>
```swift
let buildTargets = [
    TravisTarget(name: "staging", script: Script("fastlane ios distribute_staging")),
    TravisTarget(name: "testflight", script: Script("fastlane ios distribute_testflight")),
]
let buildCommand = TravisScriptCommand(name: "build", config: travisConfig, targets: buildTargets, defaultBranch: "Develop")
try bob.register(buildCommand)
```
would register a command with the name `build`. Typing `build staging` would start the lane `distribute_staging` on Travis.

### Align Version
iOS specific command used to change the `CFBundleShortVersionString` and `CFBundleVersion` values in specified `.plist` files.
<br>For example:<br>
```swift
let plistPaths: [String] = [
    "App/Info.plist",
    "siriKit/Info.plist",
    "siriKitUI/Info.plist"
]
let alignCommand = AlignVersionCommand(gitHub: gitHub, plistPaths: plistPaths, author: author)
try bob.register(alignCommand)
```
would register a command that can be invoked by typing `align 3.0 4`. Bob would then create a commit on GitHub by changing the 3 specified files.

### Bump build number
iOS specific command used to increase the `CFBundleVersion` values in specified `.plist` files. Increases the build number by 1, if it is numeric. 
<br>For example:<br>
```swift
let plistPaths: [String] = [
    "App/Info.plist",
    "siriKit/Info.plist",
    "siriKitUI/Info.plist"
]
let bumpCommand = BumpCommand(gitHub: gitHub, plistPaths: plistPaths, author: author)
try bob.register(bumpCommand)
```
would register a command that can be invoked by typing `bump`. Bob would then create a commit on GitHub by changing the 3 specified files.

## Getting started

### Creating a bot on Slack
Bob requires a Slack token in order to work. You can obtain one by creating a slack bot:<br>
1. Open the custom integration page <br>
2. Select `Bots` <br>
3. Type in a username for your bot. `bobthebuilder` works out nicely <br>
4. Copy the `API Token` field. Bob will use this to connect to slack<br>

### Starting it up
Bob can be set up just as any other Swift Package, but since it relies on [Vapor💧](https://vapor.codes/) we recommend setting it up with the Vapor toolbox. To install vapor toolbox you can follow [the manual](https://github.com/vapor/toolbox)<br>

Once you have the toolbox setup, you can start by creating a new project:<br>

```bash
vapor new BobTheBuilder
cd BobTheBuilder
```
After the template is cloned, change the `Package.swift` file to: <br>
```swift
// swift-tools-version:3.1
import PackageDescription

let package = Package(
    name: "BobTheBuilder",
    dependencies: [
        .Package(url: "https://github.com/n26/bob", majorVersion: 1)
    ]
)
```
You can delete the unused template files by running:
```bash
rm -rf Sources/App/Controllers
rm -rf Sources/App/Models
```
All of your custom code will reside in the `Sources/App` folder.<br>
Create an Xcode project by running
```bash
vapor xcode
```
Change the `Sources/App/main.swift` file to:
```swift
import Bob

let config = Bob.Configuration(slackToken: "your-slack-token")

let drop = try Droplet()
let bob = Bob(config: config, droplet: drop)

try bob.start()
```
and you're good to go. Select the `App` scheme and run it. You can now send messages to `Bob` via Slack, and it will respond.

### Using the TravisCI API
In order to use commands that communicate with the TravisCI API, you will need to provide a configuration. The configuration consists of
* Url of the repo on Travis. Along the lines of `https://api.travis-ci.com/repo/{owner%2Frepo}`
* Access token. You can obtain one by running `gem install travis && travis login && travis token`

### Using the GitHub API
In order to use commands that communicate with the GitHub API, you will need to provide a configuration. The configuration consists of
* Your GitHub username
* A personal access token with read/write permissions. See [this link](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) on instructions how to generate one
* Url of the repo on GitHub. Alogn the lines of `https://api.github.com/repos/{owner}/{repo}`

## Command chaining
Bob supports sending multiple commands using 1 slack message. Just separate commands using `|` .
<br> For example:<br>
```bash
sync strings | align 3.0 5 | build staging | build testflight
```
could be used when creating a release candidate for the app store. It would update the strings on the repository, set the version and build the app for 2 environments 

## Creating custom commands
Custom commands can be created an provided to Bob. To create a command implement the `Command` protocol.
```swift
public protocol Command {
    
    /// The name used to idenitfy a command (`hello`, `version` etc.). Case insensitive
    var name: String { get }
    
    /// String describing how to use the command.
    var usage: String { get }
    
    /// Executes the command
    ///
    /// - Parameters:
    ///   - parameters: parameters passed to the command
    ///   - sender: object used to send feedback to the user
    /// - Throws: An error is thrown if something goes wrong while executing the command, usualy while parsing the parameters
    func execute(with parameters: [String], replyingTo sender: MessageSender) throws
    
}
```    
The actual work happens in the `execute` method. All of the parameters the user typed in will be passed to the method as `[String]`. To inform the user about progress of the command, call the `send` method on the `sender` object. It will send the message to the user via Slack. If any errors occur during the execution, simply throw them.

### Using existing APIs

Bob comes with a subset of TravisCI and GitHub APIs written in swift.

#### TravisCI
Only contains a method to execute a script exposed via the `TravisScriptCommand`
#### GitHub
Contains low level methods for manipulating files and trees on GitHub. For the complete set of methods, check [GitHub.swift](Sources/Bob/APIs/GitHub/GitHub.swift)
<br>
* For utility methods to create a commit by updating a set of files, check [GitHub+FileUpdating.swift](Sources/Bob/APIs/GitHub/GitHub%2BFileUpdating.swift)
* For methods checking an existance of a specific branch, check [GitHub+BranchChecking](Sources/Bob/APIs/GitHub/GitHub%2BBranchChecking.swift)
