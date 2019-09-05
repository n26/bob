//
//  GitHubTypesResources.swift
//  BobTests
//
//  Created by Jan Chaloupecky on 20.08.19.
//

import Foundation
import Bob


protocol Response: Decodable {
    static var response: Data { get }
}

extension GitHub.Git.Commit: Response {

    static var response: Data {
        return """
        {
          "sha": "7638417db6d59f3c431d3e1f261cc637155684cd",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/7638417db6d59f3c431d3e1f261cc637155684cd",
          "author": {
            "date": "2014-11-07T22:01:45Z",
            "name": "Monalisa Octocat",
            "email": "octocat@github.com"
          },
          "committer": {
            "date": "2014-11-07T22:01:45Z",
            "name": "Monalisa Octocat",
            "email": "octocat@github.com"
          },
          "message": "added readme, because im a good github citizen",
          "tree": {
            "url": "https://api.github.com/repos/octocat/Hello-World/git/trees/691272480426f78a0138979dd3ce63b77f706feb",
            "sha": "691272480426f78a0138979dd3ce63b77f706feb"
          },
          "parents": [
            {
              "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/1acc419d4d6a9ce985db7be48c6349a0475975b5",
              "sha": "1acc419d4d6a9ce985db7be48c6349a0475975b5"
            }
          ],
          "verification": {
            "verified": false,
            "reason": "unsigned",
            "signature": null,
            "payload": null
          }
        }
        """.data(using: .utf8)!
    }
}

extension GitHub.Git.Tree: Response {
    static var response: Data = """
    {
      "sha": "9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
      "url": "https://api.github.com/repos/octocat/Hello-World/trees/9fb037999f264ba9a7fc6274d15fa3ae2ab98312",
      "tree": [
        {
          "path": "file.rb",
          "mode": "100644",
          "type": "blob",
          "size": 30,
          "sha": "44b4fc6d56897b048c772eb4087f854f46256132",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/44b4fc6d56897b048c772eb4087f854f46256132"
        },
        {
          "path": "subdir",
          "mode": "040000",
          "type": "tree",
          "sha": "f484d249c660418515fb01c2b9662073663c242e",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/f484d249c660418515fb01c2b9662073663c242e"
        },
        {
          "path": "exec_file",
          "mode": "100755",
          "type": "blob",
          "size": 75,
          "sha": "45b983be36b73c0788dc9cbcb76cbb80fc7bb057",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/blobs/45b983be36b73c0788dc9cbcb76cbb80fc7bb057"
        }
      ],
      "truncated": false
    }
    """.data(using: .utf8)!
}

extension GitHub.Repos.Commit: Response {
    static var response: Data = """
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
      "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
      "commit": {
        "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "author": {
          "name": "Monalisa Octocat",
          "email": "support@github.com",
          "date": "2011-04-14T16:00:49Z"
        },
        "committer": {
          "name": "Monalisa Octocat",
          "email": "support@github.com",
          "date": "2011-04-14T16:00:49Z"
        },
        "message": "Fix all the bugs",
        "tree": {
          "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
        },
        "comment_count": 0,
        "verification": {
          "verified": false,
          "reason": "unsigned",
          "signature": null,
          "payload": null
        }
      },
      "author": {
        "login": "octocat",
        "id": 1,
        "node_id": "MDQ6VXNlcjE=",
        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
        "gravatar_id": "",
        "url": "https://api.github.com/users/octocat",
        "html_url": "https://github.com/octocat",
        "followers_url": "https://api.github.com/users/octocat/followers",
        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
        "organizations_url": "https://api.github.com/users/octocat/orgs",
        "repos_url": "https://api.github.com/users/octocat/repos",
        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
        "received_events_url": "https://api.github.com/users/octocat/received_events",
        "type": "User",
        "site_admin": false
      },
      "committer": {
        "login": "octocat",
        "id": 1,
        "node_id": "MDQ6VXNlcjE=",
        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
        "gravatar_id": "",
        "url": "https://api.github.com/users/octocat",
        "html_url": "https://github.com/octocat",
        "followers_url": "https://api.github.com/users/octocat/followers",
        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
        "organizations_url": "https://api.github.com/users/octocat/orgs",
        "repos_url": "https://api.github.com/users/octocat/repos",
        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
        "received_events_url": "https://api.github.com/users/octocat/received_events",
        "type": "User",
        "site_admin": false
      },
      "parents": [
        {
          "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
        }
      ],
      "stats": {
        "additions": 104,
        "deletions": 4,
        "total": 108
      },
      "files": [
        {
          "filename": "file1.txt",
          "additions": 10,
          "deletions": 2,
          "changes": 12,
          "status": "modified",
          "raw_url": "https://github.com/octocat/Hello-World/raw/7ca483543807a51b6079e54ac4cc392bc29ae284/file1.txt",
          "blob_url": "https://github.com/octocat/Hello-World/blob/7ca483543807a51b6079e54ac4cc392bc29ae284/file1.txt",
          "patch": ""
        }
      ]
    }
    """.data(using: .utf8)!
}

extension GitHub.Repos.Tag: Response {
    static var response: Data = """
      {
        "name": "1.3.3",
        "zipball_url": "https://api.github.com/repos/n26/bob/zipball/1.3.3",
        "tarball_url": "https://api.github.com/repos/n26/bob/tarball/1.3.3",
        "commit": {
          "sha": "e03cdfe5c5c94cee32e49851e765a75bdcebfbdc",
          "url": "https://api.github.com/repos/n26/bob/commits/e03cdfe5c5c94cee32e49851e765a75bdcebfbdc"
        },
        "node_id": "MDM6UmVmODQwOTI4OTc6MS4zLjM="
      }
    """.data(using: .utf8)!
}


extension GitHub.Pulls.Pull: Response {
    static var response: Data = """
    {
      "url": "https://api.github.com/repos/n26/bob/pulls/9",
      "id": 165072792,
      "node_id": "MDExOlB1bGxSZXF1ZXN0MTY1MDcyNzky",
      "html_url": "https://github.com/n26/bob/pull/9",
      "diff_url": "https://github.com/n26/bob/pull/9.diff",
      "patch_url": "https://github.com/n26/bob/pull/9.patch",
      "issue_url": "https://api.github.com/repos/n26/bob/issues/9",
      "number": 9,
      "state": "open",
      "locked": false,
      "title": "Conform to `ConfigInitializable`",
      "user": {
        "login": "mosamer",
        "id": 1731640,
        "node_id": "MDQ6VXNlcjE3MzE2NDA=",
        "avatar_url": "https://avatars1.githubusercontent.com/u/1731640?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/mosamer",
        "html_url": "https://github.com/mosamer",
        "followers_url": "https://api.github.com/users/mosamer/followers",
        "following_url": "https://api.github.com/users/mosamer/following{/other_user}",
        "gists_url": "https://api.github.com/users/mosamer/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/mosamer/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/mosamer/subscriptions",
        "organizations_url": "https://api.github.com/users/mosamer/orgs",
        "repos_url": "https://api.github.com/users/mosamer/repos",
        "events_url": "https://api.github.com/users/mosamer/events{/privacy}",
        "received_events_url": "https://api.github.com/users/mosamer/received_events",
        "type": "User",
        "site_admin": false
      },
      "body": "This PR adds support for initializing Bob, TravisCI and GitHub using Vapor configs. This allows an initialization process that is more inline with other Vapor projects and tutorials.",
      "created_at": "2018-01-25T09:53:16Z",
      "updated_at": "2018-07-03T12:23:13Z",
      "closed_at": null,
      "merged_at": null,
      "merge_commit_sha": "70a364942abd9b09aed3aaf715eb4708ee7adf76",
      "assignee": null,
      "assignees": [

      ],
      "requested_reviewers": [

      ],
      "requested_teams": [

      ],
      "labels": [

      ],
      "milestone": null,
      "commits_url": "https://api.github.com/repos/n26/bob/pulls/9/commits",
      "review_comments_url": "https://api.github.com/repos/n26/bob/pulls/9/comments",
      "review_comment_url": "https://api.github.com/repos/n26/bob/pulls/comments{/number}",
      "comments_url": "https://api.github.com/repos/n26/bob/issues/9/comments",
      "statuses_url": "https://api.github.com/repos/n26/bob/statuses/d5bfa81b4994b00d37462595cf78219623963fde",
      "head": {
        "label": "mosamer:master",
        "ref": "master",
        "sha": "d5bfa81b4994b00d37462595cf78219623963fde",
        "user": {
          "login": "mosamer",
          "id": 1731640,
          "node_id": "MDQ6VXNlcjE3MzE2NDA=",
          "avatar_url": "https://avatars1.githubusercontent.com/u/1731640?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/mosamer",
          "html_url": "https://github.com/mosamer",
          "followers_url": "https://api.github.com/users/mosamer/followers",
          "following_url": "https://api.github.com/users/mosamer/following{/other_user}",
          "gists_url": "https://api.github.com/users/mosamer/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/mosamer/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/mosamer/subscriptions",
          "organizations_url": "https://api.github.com/users/mosamer/orgs",
          "repos_url": "https://api.github.com/users/mosamer/repos",
          "events_url": "https://api.github.com/users/mosamer/events{/privacy}",
          "received_events_url": "https://api.github.com/users/mosamer/received_events",
          "type": "User",
          "site_admin": false
        },
        "repo": {
          "id": 118870169,
          "node_id": "MDEwOlJlcG9zaXRvcnkxMTg4NzAxNjk=",
          "name": "bob",
          "full_name": "mosamer/bob",
          "private": false,
          "owner": {
            "login": "mosamer",
            "id": 1731640,
            "node_id": "MDQ6VXNlcjE3MzE2NDA=",
            "avatar_url": "https://avatars1.githubusercontent.com/u/1731640?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/mosamer",
            "html_url": "https://github.com/mosamer",
            "followers_url": "https://api.github.com/users/mosamer/followers",
            "following_url": "https://api.github.com/users/mosamer/following{/other_user}",
            "gists_url": "https://api.github.com/users/mosamer/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/mosamer/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/mosamer/subscriptions",
            "organizations_url": "https://api.github.com/users/mosamer/orgs",
            "repos_url": "https://api.github.com/users/mosamer/repos",
            "events_url": "https://api.github.com/users/mosamer/events{/privacy}",
            "received_events_url": "https://api.github.com/users/mosamer/received_events",
            "type": "User",
            "site_admin": false
          },
          "html_url": "https://github.com/mosamer/bob",
          "description": null,
          "fork": true,
          "url": "https://api.github.com/repos/mosamer/bob",
          "forks_url": "https://api.github.com/repos/mosamer/bob/forks",
          "keys_url": "https://api.github.com/repos/mosamer/bob/keys{/key_id}",
          "collaborators_url": "https://api.github.com/repos/mosamer/bob/collaborators{/collaborator}",
          "teams_url": "https://api.github.com/repos/mosamer/bob/teams",
          "hooks_url": "https://api.github.com/repos/mosamer/bob/hooks",
          "issue_events_url": "https://api.github.com/repos/mosamer/bob/issues/events{/number}",
          "events_url": "https://api.github.com/repos/mosamer/bob/events",
          "assignees_url": "https://api.github.com/repos/mosamer/bob/assignees{/user}",
          "branches_url": "https://api.github.com/repos/mosamer/bob/branches{/branch}",
          "tags_url": "https://api.github.com/repos/mosamer/bob/tags",
          "blobs_url": "https://api.github.com/repos/mosamer/bob/git/blobs{/sha}",
          "git_tags_url": "https://api.github.com/repos/mosamer/bob/git/tags{/sha}",
          "git_refs_url": "https://api.github.com/repos/mosamer/bob/git/refs{/sha}",
          "trees_url": "https://api.github.com/repos/mosamer/bob/git/trees{/sha}",
          "statuses_url": "https://api.github.com/repos/mosamer/bob/statuses/{sha}",
          "languages_url": "https://api.github.com/repos/mosamer/bob/languages",
          "stargazers_url": "https://api.github.com/repos/mosamer/bob/stargazers",
          "contributors_url": "https://api.github.com/repos/mosamer/bob/contributors",
          "subscribers_url": "https://api.github.com/repos/mosamer/bob/subscribers",
          "subscription_url": "https://api.github.com/repos/mosamer/bob/subscription",
          "commits_url": "https://api.github.com/repos/mosamer/bob/commits{/sha}",
          "git_commits_url": "https://api.github.com/repos/mosamer/bob/git/commits{/sha}",
          "comments_url": "https://api.github.com/repos/mosamer/bob/comments{/number}",
          "issue_comment_url": "https://api.github.com/repos/mosamer/bob/issues/comments{/number}",
          "contents_url": "https://api.github.com/repos/mosamer/bob/contents/{+path}",
          "compare_url": "https://api.github.com/repos/mosamer/bob/compare/{base}...{head}",
          "merges_url": "https://api.github.com/repos/mosamer/bob/merges",
          "archive_url": "https://api.github.com/repos/mosamer/bob/{archive_format}{/ref}",
          "downloads_url": "https://api.github.com/repos/mosamer/bob/downloads",
          "issues_url": "https://api.github.com/repos/mosamer/bob/issues{/number}",
          "pulls_url": "https://api.github.com/repos/mosamer/bob/pulls{/number}",
          "milestones_url": "https://api.github.com/repos/mosamer/bob/milestones{/number}",
          "notifications_url": "https://api.github.com/repos/mosamer/bob/notifications{?since,all,participating}",
          "labels_url": "https://api.github.com/repos/mosamer/bob/labels{/name}",
          "releases_url": "https://api.github.com/repos/mosamer/bob/releases{/id}",
          "deployments_url": "https://api.github.com/repos/mosamer/bob/deployments",
          "created_at": "2018-01-25T06:06:32Z",
          "updated_at": "2018-07-03T12:23:12Z",
          "pushed_at": "2018-01-25T10:41:13Z",
          "git_url": "git://github.com/mosamer/bob.git",
          "ssh_url": "git@github.com:mosamer/bob.git",
          "clone_url": "https://github.com/mosamer/bob.git",
          "svn_url": "https://github.com/mosamer/bob",
          "homepage": null,
          "size": 62,
          "stargazers_count": 0,
          "watchers_count": 0,
          "language": "Swift",
          "has_issues": false,
          "has_projects": true,
          "has_downloads": true,
          "has_wiki": true,
          "has_pages": false,
          "forks_count": 0,
          "mirror_url": null,
          "archived": false,
          "disabled": false,
          "open_issues_count": 0,
          "license": {
            "key": "gpl-3.0",
            "name": "GNU General Public License v3.0",
            "spdx_id": "GPL-3.0",
            "url": "https://api.github.com/licenses/gpl-3.0",
            "node_id": "MDc6TGljZW5zZTk="
          },
          "forks": 0,
          "open_issues": 0,
          "watchers": 0,
          "default_branch": "master"
        }
      },
      "base": {
        "label": "n26:master",
        "ref": "master",
        "sha": "3a10cb92209fd218f763b2ad745ffecfd9de3ca3",
        "user": {
          "login": "n26",
          "id": 30530034,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjMwNTMwMDM0",
          "avatar_url": "https://avatars3.githubusercontent.com/u/30530034?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/n26",
          "html_url": "https://github.com/n26",
          "followers_url": "https://api.github.com/users/n26/followers",
          "following_url": "https://api.github.com/users/n26/following{/other_user}",
          "gists_url": "https://api.github.com/users/n26/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/n26/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/n26/subscriptions",
          "organizations_url": "https://api.github.com/users/n26/orgs",
          "repos_url": "https://api.github.com/users/n26/repos",
          "events_url": "https://api.github.com/users/n26/events{/privacy}",
          "received_events_url": "https://api.github.com/users/n26/received_events",
          "type": "Organization",
          "site_admin": false
        },
        "repo": {
          "id": 84092897,
          "node_id": "MDEwOlJlcG9zaXRvcnk4NDA5Mjg5Nw==",
          "name": "bob",
          "full_name": "n26/bob",
          "private": false,
          "owner": {
            "login": "n26",
            "id": 30530034,
            "node_id": "MDEyOk9yZ2FuaXphdGlvbjMwNTMwMDM0",
            "avatar_url": "https://avatars3.githubusercontent.com/u/30530034?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/n26",
            "html_url": "https://github.com/n26",
            "followers_url": "https://api.github.com/users/n26/followers",
            "following_url": "https://api.github.com/users/n26/following{/other_user}",
            "gists_url": "https://api.github.com/users/n26/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/n26/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/n26/subscriptions",
            "organizations_url": "https://api.github.com/users/n26/orgs",
            "repos_url": "https://api.github.com/users/n26/repos",
            "events_url": "https://api.github.com/users/n26/events{/privacy}",
            "received_events_url": "https://api.github.com/users/n26/received_events",
            "type": "Organization",
            "site_admin": false
          },
          "html_url": "https://github.com/n26/bob",
          "description": "Extensible Slack Bot used to communicate with TravisCI and GitHub",
          "fork": false,
          "url": "https://api.github.com/repos/n26/bob",
          "forks_url": "https://api.github.com/repos/n26/bob/forks",
          "keys_url": "https://api.github.com/repos/n26/bob/keys{/key_id}",
          "collaborators_url": "https://api.github.com/repos/n26/bob/collaborators{/collaborator}",
          "teams_url": "https://api.github.com/repos/n26/bob/teams",
          "hooks_url": "https://api.github.com/repos/n26/bob/hooks",
          "issue_events_url": "https://api.github.com/repos/n26/bob/issues/events{/number}",
          "events_url": "https://api.github.com/repos/n26/bob/events",
          "assignees_url": "https://api.github.com/repos/n26/bob/assignees{/user}",
          "branches_url": "https://api.github.com/repos/n26/bob/branches{/branch}",
          "tags_url": "https://api.github.com/repos/n26/bob/tags",
          "blobs_url": "https://api.github.com/repos/n26/bob/git/blobs{/sha}",
          "git_tags_url": "https://api.github.com/repos/n26/bob/git/tags{/sha}",
          "git_refs_url": "https://api.github.com/repos/n26/bob/git/refs{/sha}",
          "trees_url": "https://api.github.com/repos/n26/bob/git/trees{/sha}",
          "statuses_url": "https://api.github.com/repos/n26/bob/statuses/{sha}",
          "languages_url": "https://api.github.com/repos/n26/bob/languages",
          "stargazers_url": "https://api.github.com/repos/n26/bob/stargazers",
          "contributors_url": "https://api.github.com/repos/n26/bob/contributors",
          "subscribers_url": "https://api.github.com/repos/n26/bob/subscribers",
          "subscription_url": "https://api.github.com/repos/n26/bob/subscription",
          "commits_url": "https://api.github.com/repos/n26/bob/commits{/sha}",
          "git_commits_url": "https://api.github.com/repos/n26/bob/git/commits{/sha}",
          "comments_url": "https://api.github.com/repos/n26/bob/comments{/number}",
          "issue_comment_url": "https://api.github.com/repos/n26/bob/issues/comments{/number}",
          "contents_url": "https://api.github.com/repos/n26/bob/contents/{+path}",
          "compare_url": "https://api.github.com/repos/n26/bob/compare/{base}...{head}",
          "merges_url": "https://api.github.com/repos/n26/bob/merges",
          "archive_url": "https://api.github.com/repos/n26/bob/{archive_format}{/ref}",
          "downloads_url": "https://api.github.com/repos/n26/bob/downloads",
          "issues_url": "https://api.github.com/repos/n26/bob/issues{/number}",
          "pulls_url": "https://api.github.com/repos/n26/bob/pulls{/number}",
          "milestones_url": "https://api.github.com/repos/n26/bob/milestones{/number}",
          "notifications_url": "https://api.github.com/repos/n26/bob/notifications{?since,all,participating}",
          "labels_url": "https://api.github.com/repos/n26/bob/labels{/name}",
          "releases_url": "https://api.github.com/repos/n26/bob/releases{/id}",
          "deployments_url": "https://api.github.com/repos/n26/bob/deployments",
          "created_at": "2017-03-06T16:03:00Z",
          "updated_at": "2019-08-08T13:28:01Z",
          "pushed_at": "2019-09-03T12:50:47Z",
          "git_url": "git://github.com/n26/bob.git",
          "ssh_url": "git@github.com:n26/bob.git",
          "clone_url": "https://github.com/n26/bob.git",
          "svn_url": "https://github.com/n26/bob",
          "homepage": "",
          "size": 138,
          "stargazers_count": 61,
          "watchers_count": 61,
          "language": "Swift",
          "has_issues": true,
          "has_projects": false,
          "has_downloads": false,
          "has_wiki": true,
          "has_pages": false,
          "forks_count": 9,
          "mirror_url": null,
          "archived": false,
          "disabled": false,
          "open_issues_count": 1,
          "license": {
            "key": "gpl-3.0",
            "name": "GNU General Public License v3.0",
            "spdx_id": "GPL-3.0",
            "url": "https://api.github.com/licenses/gpl-3.0",
            "node_id": "MDc6TGljZW5zZTk="
          },
          "forks": 9,
          "open_issues": 1,
          "watchers": 61,
          "default_branch": "master"
        }
      },
      "_links": {
        "self": {
          "href": "https://api.github.com/repos/n26/bob/pulls/9"
        },
        "html": {
          "href": "https://github.com/n26/bob/pull/9"
        },
        "issue": {
          "href": "https://api.github.com/repos/n26/bob/issues/9"
        },
        "comments": {
          "href": "https://api.github.com/repos/n26/bob/issues/9/comments"
        },
        "review_comments": {
          "href": "https://api.github.com/repos/n26/bob/pulls/9/comments"
        },
        "review_comment": {
          "href": "https://api.github.com/repos/n26/bob/pulls/comments{/number}"
        },
        "commits": {
          "href": "https://api.github.com/repos/n26/bob/pulls/9/commits"
        },
        "statuses": {
          "href": "https://api.github.com/repos/n26/bob/statuses/d5bfa81b4994b00d37462595cf78219623963fde"
        }
      },
      "author_association": "FIRST_TIME_CONTRIBUTOR"
    }
    """.data(using: .utf8)!
}

extension GitHub.Pulls.Review: Response {
    static var response: Data = """
        {
          "id": 91474857,
          "node_id": "MDE3OlB1bGxSZXF1ZXN0UmV2aWV3OTE0NzQ4NTc=",
          "user": {
            "login": "i-dama",
            "id": 2226475,
            "node_id": "MDQ6VXNlcjIyMjY0NzU=",
            "avatar_url": "https://avatars1.githubusercontent.com/u/2226475?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/i-dama",
            "html_url": "https://github.com/i-dama",
            "followers_url": "https://api.github.com/users/i-dama/followers",
            "following_url": "https://api.github.com/users/i-dama/following{/other_user}",
            "gists_url": "https://api.github.com/users/i-dama/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/i-dama/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/i-dama/subscriptions",
            "organizations_url": "https://api.github.com/users/i-dama/orgs",
            "repos_url": "https://api.github.com/users/i-dama/repos",
            "events_url": "https://api.github.com/users/i-dama/events{/privacy}",
            "received_events_url": "https://api.github.com/users/i-dama/received_events",
            "type": "User",
            "site_admin": false
          },
          "body": "Great PR, thanks for your contribution Do you think it would make sense to move the config name",
          "state": "COMMENTED",
          "html_url": "https://github.com/n26/bob/pull/9#pullrequestreview-91474857",
          "pull_request_url": "https://api.github.com/repos/n26/bob/pulls/9",
          "author_association": "MEMBER",
          "_links": {
            "html": {
              "href": "https://github.com/n26/bob/pull/9#pullrequestreview-91474857"
            },
            "pull_request": {
              "href": "https://api.github.com/repos/n26/bob/pulls/9"
            }
          },
          "submitted_at": "2018-01-25T10:33:02Z",
          "commit_id": "ec863f8cee458dd1bfcf9c5c0546e0832291c761"
        }
    """.data(using: .utf8)!
}
