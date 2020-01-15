//
//  main.swift
//  FirstCourseFinalTask
//
//  Copyright © 2017 E-Legion. All rights reserved.
//

import Foundation
import FirstCourseFinalTaskChecker

struct User: UserProtocol {
  var id: GenericIdentifier<UserProtocol>
  var username: String
  var fullName: String
  var avatarURL: URL?
  var followsCount: Int
  var followedByCount: Int
  var currentUserFollowsThisUser: Bool
  var currentUserIsFollowedByThisUser: Bool
 
  init(id: GenericIdentifier<UserProtocol>,
       username: String,
       fullName: String,
       avatarURL: URL?,
       followsCount: Int,
       followedByCount: Int,
       currentUserFollowsThisUser: Bool,
       currentUserIsFollowedByThisUser: Bool){
    self.id = id
    self.username = username
    self.fullName = fullName
    self.avatarURL = avatarURL
    self.followsCount = followsCount
    self.followedByCount = followedByCount
    self.currentUserFollowsThisUser = currentUserFollowsThisUser
    self.currentUserIsFollowedByThisUser = currentUserIsFollowedByThisUser
  }
}

class UsersStorage: UsersStorageProtocol {
  var users: [UserInitialData]
  var followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)]
  var currentUserID: GenericIdentifier<UserProtocol>
  var count: Int {return users.count }
  
  required init?(users: [UserInitialData],
                 followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)],
                 currentUserID: GenericIdentifier<UserProtocol>) {
    self.users = users
    self.followers = followers
    
    if users.first(where: {$0.id == currentUserID}) != nil {
      self.currentUserID = currentUserID
    } else {return nil}
  }
    
  func currentUser() -> UserProtocol {
    var currUser: UserProtocol = User(id: "", username: "", fullName: "", avatarURL: nil, followsCount: 0, followedByCount: 0, currentUserFollowsThisUser: false, currentUserIsFollowedByThisUser: false)
    
    for user in users {
      if user.id == currentUserID {
       currUser = User(id: currentUserID,
                        username: user.username,
                        fullName: user.fullName,
                        avatarURL: user.avatarURL,
                        followsCount: {countFollows(userID: currentUserID)}() ,
                        followedByCount: {countFollowedBy(userID: currentUserID)}(),
                        currentUserFollowsThisUser: false,
                        currentUserIsFollowedByThisUser: false)
      }
    }
    return currUser
  }
  
  func user(with userID: GenericIdentifier<UserProtocol>) -> UserProtocol? {
    var userToFind: User?
    
    for user in users {
      if user.id == userID {
        userToFind = User(id: user.id,
                             username: user.username,
                             fullName: user.fullName,
                             avatarURL: user.avatarURL,
                             followsCount: {countFollows(userID: user.id)}(),
                             followedByCount: {countFollowedBy(userID: user.id)}(),
                             currentUserFollowsThisUser:  {
                              var isFollowing: Bool = false
                              for follower in followers {
                                if follower == (currentUserID, userID) {
                                  isFollowing = true
                                }
                              }
                              return isFollowing
                              }(),
                             currentUserIsFollowedByThisUser: {
                              var isFollowed: Bool = false
                              for (thisUserID, userIDFollowedByThisUser) in followers {
                                if thisUserID == user.id &&
                                  userIDFollowedByThisUser == currentUserID {
                                  isFollowed = true
                                }
                              }
                              return isFollowed
                             }() )
      }
    }
    return userToFind
  }
  
  func findUsers(by searchString: String) -> [UserProtocol] {
    var usersToFind = [UserProtocol]()
    var userWithString: UserProtocol
    
    for user in users {
      if user.username == searchString || user.fullName == searchString {
        userWithString = User(id: user.id,
                                 username: user.username,
                                 fullName: user.fullName,
                                 avatarURL: user.avatarURL,
                                 followsCount: {countFollows(userID: user.id)}(),
                                 followedByCount: {countFollowedBy(userID: user.id)}(),
                                 currentUserFollowsThisUser: {
                                  var isFollowing: Bool = false
                                  for (thisUserID, userIDFollowedByThisUser) in followers {
                                    if thisUserID == currentUserID &&
                                      userIDFollowedByThisUser == user.id {
                                      isFollowing = true
                                    }
                                     }
                                  return isFollowing
                                 }(),
                                 currentUserIsFollowedByThisUser: {
                                  var isFollowed: Bool = false
                                  for (thisUserID, userIDFollowedByThisUser) in followers {
                                    if thisUserID == user.id &&
                                      userIDFollowedByThisUser == currentUserID {
                                      isFollowed = true
                                    }
                                   }
                                  return isFollowed
                                 }())
        usersToFind.append(userWithString)
      }
    }
    return usersToFind
  }
  
  func follow(_ userIDToFollow: GenericIdentifier<UserProtocol>) -> Bool {
    var follower: (GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)
    var isFollowed: Bool = false
    for user in users {
      if user.id == userIDToFollow {
        if followers.contains(where: {$0 == (currentUserID, userIDToFollow)}) {
          isFollowed = true
        } else {
          follower = (currentUserID, userIDToFollow)
          followers.append(follower)
          isFollowed = true
        }
      }
    }
    return isFollowed
  }
  
  func unfollow(_ userIDToUnfollow: GenericIdentifier<UserProtocol>) -> Bool {
    var isUnfollowed: Bool = false
    for user in users {
      if user.id == userIDToUnfollow {
        for (index, follower) in followers.enumerated() {
          if follower == (currentUserID, userIDToUnfollow) {
            followers.remove(at: index)
            isUnfollowed = true
          } else {
            isUnfollowed = true
          }
        }
      } 
    }
    return isUnfollowed
  }
  
  func usersFollowingUser(with userID: GenericIdentifier<UserProtocol>) -> [UserProtocol]? {
    var usersFollowing: [UserProtocol]?

    for user1 in users {
      if user1.id == userID { //если есть в массиве юзеров
        usersFollowing = []
        for (thisUserID, userIDFollowedByThisUser) in followers { //проходим по массиву подписчиков
          if userIDFollowedByThisUser == userID {
            guard let userFollowing = user(with: thisUserID) else {return usersFollowing}
            usersFollowing?.append(userFollowing)
          }
        }
      }
    }
    return usersFollowing
  }
  
  func usersFollowedByUser(with userID: GenericIdentifier<UserProtocol>) -> [UserProtocol]? {
    var usersFollowedByUser: [UserProtocol]?
    var userFollowedByUser: UserProtocol
    
    for user1 in users {
      if user1.id == userID { //если есть в массиве юзеров
        usersFollowedByUser = []
        for (thisUserID,userIDFollowedByThisUser) in followers { //проходим по массиву подписчиков
          if thisUserID == userID {
            userFollowedByUser = user(with: userIDFollowedByThisUser)!
            usersFollowedByUser?.append(userFollowedByUser)
          }
        }
      }
    }
    return usersFollowedByUser
  }
}

extension UsersStorage {
  func countFollows (userID: GenericIdentifier<UserProtocol>)-> Int {
    var userFollows: [GenericIdentifier<UserProtocol>] = []
    for (thisUserID, userIDFollowedByThisUser) in followers {
      if thisUserID == userID  {
        userFollows.append(userIDFollowedByThisUser)
      }
    }
    return userFollows.count
  }
  
  func countFollowedBy (userID: GenericIdentifier<UserProtocol>)-> Int {
    var usersFollowing: [GenericIdentifier<UserProtocol>] = []
    
    for (thisUserID, userIDFollowedByThisUser) in followers {
      if userIDFollowedByThisUser == userID  {
        usersFollowing.append(thisUserID)
      }
    }
    return usersFollowing.count
  }
}

struct Post: PostProtocol {
  var id: Self.Identifier
  var author: GenericIdentifier<UserProtocol>
  var description: String
  var imageURL: URL
  var createdTime: Date
  var currentUserLikesThisPost: Bool
  var likedByCount: Int
  
}

class PostsStorage: PostsStorageProtocol {
  var posts: [PostInitialData]
  var likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)]
  var currentUserID: GenericIdentifier<UserProtocol>
  
  required init(posts: [PostInitialData],
                likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)],
                currentUserID: GenericIdentifier<UserProtocol>) {
    self.posts = posts
    self.likes = likes
    self.currentUserID = currentUserID
  }
  
  var count: Int {return posts.count }
  
  func post(with postID: GenericIdentifier<PostProtocol>) -> PostProtocol? {
    var postWithID: Post?
    for post in posts {
      if post.id == postID {
        postWithID = Post(id: post.id,
                          author: post.author,
                          description: post.description,
                          imageURL: post.imageURL,
                          createdTime: post.createdTime,
                          currentUserLikesThisPost: {
                          var isLiked: Bool = false
                          for (userID, postId) in likes {
                            if userID == currentUserID && postId == post.id  {
                            isLiked = true
                            }
                          }
                          return isLiked
                          }(),
                          likedByCount: {countLikes(with: postID)}())
      }
    }
    return postWithID
  }
  
  func findPosts(by authorID: GenericIdentifier<UserProtocol>) -> [PostProtocol] {
    var postsByAuthor: [PostProtocol] = []
    for post in posts {
      if post.author == authorID {
        let postByAuthor = Post(id: post.id,
                                author: post.author,
                                description: post.description,
                                imageURL: post.imageURL,
                                createdTime: post.createdTime,
                                currentUserLikesThisPost: {
                                var isLiked: Bool = false
                                for (userID, postId) in likes {
                                  if userID == currentUserID && postId == post.id  {
                                  isLiked = true
                                  }
                                 }
                                return isLiked
                                }(),
                                likedByCount: {countLikes(with: post.id)}())
        postsByAuthor.append(postByAuthor)
      }
    }
    return postsByAuthor
  }
  
  func findPosts(by searchString: String) -> [PostProtocol] {
    var postsWithString: [PostProtocol] = []
    for post in posts {
      if post.description.contains(searchString) {
        let postWithString = Post(id: post.id,
                                  author: post.author,
                                  description: post.description,
                                  imageURL: post.imageURL,
                                  createdTime: post.createdTime,
                                  currentUserLikesThisPost: {
                                    var isLiked: Bool = false
                                    for (userID, postId) in likes {
                                     if userID == currentUserID && postId == post.id  {
                                      isLiked = true
                                      }
                                     }
                                    return isLiked
                                  }(),
                                  likedByCount: {countLikes(with: post.id)}())
        postsWithString.append(postWithString)
      }
    }
    return postsWithString
  }
  
  func likePost(with postID: GenericIdentifier<PostProtocol>) -> Bool {
    var isLiked: Bool = false
    
    for post in posts {
      if post.id == postID {
        if likes.contains(where: {$0 == (currentUserID, postID)}) {
          isLiked = true
        } else {
          likes.append((currentUserID, postID))
          isLiked = true
        }
      }
    }
    return isLiked
  }
  
  func unlikePost(with postID: GenericIdentifier<PostProtocol>) -> Bool {
    var isUnliked: Bool = false
    
    for post in posts {
      if post.id == postID {
        for (index, like) in likes.enumerated() {
          if like == (currentUserID, postID) {
            likes.remove(at: index)
            isUnliked = true
          } else {isUnliked = true}
        }
      }
    }
    return isUnliked
  }
  
  func usersLikedPost(with postID: GenericIdentifier<PostProtocol>) -> [GenericIdentifier<UserProtocol>]? {
    var usersIDLikedThisPost: [GenericIdentifier<UserProtocol>]?
    
    for post in posts {
      if post.id == postID {
        usersIDLikedThisPost = []
        for (userId, postId) in likes {
          if postId == post.id {
            usersIDLikedThisPost?.append(userId)
          }
        }
      }
    }
    return usersIDLikedThisPost
  }
}

extension PostsStorage {
  func countLikes (with postID: GenericIdentifier<PostProtocol>) -> Int {
  var usersIDLikedThisPost: [GenericIdentifier<UserProtocol>]? = []
    
     for post in posts {
       if post.id == postID {
         for (userId, postId) in likes {
           if postId == postID {
             usersIDLikedThisPost?.append(userId)
           }
         }
       }
     }
    return usersIDLikedThisPost?.count ?? 0
  }
}

let checker = Checker(usersStorageClass: UsersStorage.self,
                      postsStorageClass: PostsStorage.self)
checker.run()

