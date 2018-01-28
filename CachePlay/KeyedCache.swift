//
//  KeyedCache.swift
//  CachePlay
//
//  Created by Brian Cordan Young on 1/28/18.
//  Copyright © 2018 BrianCordanYoung. All rights reserved.
//

import Swift

/// A Key Value storage that holds a limited number of items.
/// When the limit is reached, the least recently accessed item is discarded
internal struct KeyedCache<T, Key: Hashable> {
  
  /// A Node for the linked list used to store the order of most recent access.
  /// The `CacheNode` is stored in a dictionary, and the dictionary keys are
  /// used as references to the previous and next `CacheNode`s.
  internal struct CacheNode<T>: CustomStringConvertible {
    
    let item: T
    var next: Key?
    var previous: Key?
    
    var description: String {
      let describe = CacheNode.describe
      return "value: \(item) previous: \(describe(previous)) next: \(describe(next))"
    }
    
    internal static func describe(key: Key?) -> String {
      var description = "___"
      if let key = key {
        description = String(describing: key)
      }
      return description
    }
  }
  
  /// Maximum items to store in cache
  private var limit: Int
  /// Head of the linked list that stores the most recent access
  private var head:  Key?
  /// Tail of the linked list that stores the most recent access
  private var tail:  Key?
  /// Dictionary to store each `CacheNode`.
  private var cache: [Key:CacheNode<T>] = [:]
  
  /// LimitedCache
  ///
  /// - Parameter itemLimit: Maximum items to store in cache
  init(itemLimit: UInt) {
    limit = Int(itemLimit)
  }
  
  /// LimitedCache
  ///
  /// - Parameters:
  ///   - item: An `item` to store
  ///   - key: The `key` used to reference and store a `CacheNode` in the cache
  ///   - itemLimit: Maximum items to store in cache
  init(item: T, key: Key, itemLimit: UInt) {
    limit = Int(itemLimit)
    add(item: item, withKey: key)
  }
  
  
  /// Add and item to the cache at the top of the stack, temporarily
  /// preventing it from being discarded when adding a new item.
  ///
  /// - Parameters:
  ///   - item: `item` to store
  ///   - key: The `key` used to reference and store a Node in the cache
  internal mutating func add(item: T, withKey key: Key) {
    let node = CacheNode(item: item, next: .none, previous: .none)
    push(node: node, withKey: key)
  }
  
  
  /// Retrive the items for a given `key`. This item will be promoted to the most
  /// recently accessed `item`, temporarily preventing it from being discarded
  /// when adding a new `item`.
  ///
  /// - Parameter key: The `key` used to reference and store a Node in the cache
  /// - Returns: An `item`
  internal mutating func itemFor(key: Key) -> T? {
    guard let node = nodeFor(key: key)
      else  { return .none }
    
    setHeadNode(node: node, withKey: key)
    return node.item
  }
  
  
  /// An array of all items in the order they have been last accessed.
  /// Does not change the order of the items.
  internal var allItems: Array<T> {
    var items: Array<T> = []
    var nextKey: Key? = head
    
    while (nextKey != .none) {
      guard let key = nextKey,
        let node = cache[key]
        else { break }
      items.append(node.item)
      nextKey = node.next
    }
    
    return items
  }
  
  /// An array of all items in the order they have been last accessed.
  /// Does not change the order of the items.
  internal var allKeys: Array<Key> {
    var keys: Array<Key> = []
    var nextKey: Key? = head
    
    while (nextKey != .none) {
      guard let key = nextKey,
        let node = cache[key]
        else { break }
      keys.append(key)
      nextKey = node.next
    }
    
    return keys
  }
  
  
  // Can't impliment subscript because it does not allow for mutation
  // and the side effect of reordering of the linked list.
  //  subscript(key: Key, item: T) -> T? {
  //    get {
  //      // Get the item, loose the side effect of reordering linked list
  //      // var tmp = self
  //      // let result = tmp.fetchItemFor(key: key)
  //      return fetchItemFor(key: key)
  //    }
  //
  //    set {
  //      add(item: item, withKey: key)
  //    }
  //  }
  
  
  /// Return a node for the given key
  ///
  /// - Parameter key: The `key` used to reference and store a Node in the cache
  /// - Returns: A `CacheNode`
  private func nodeFor(key: Key) -> CacheNode<T>? {
    return cache[key]
  }
  
  /// Push a node to the head of the linked list and store in the cache.
  ///
  /// - Parameters:
  ///   - node: A `CacheNode`
  ///   - key: The `key` used to reference and store a `CacheNode` in the cache
  ///   - Note: If a `CacheNode` exists for a given key, it will be discarded from
  ///           the cache, and replaced by the input `CacheNode`.
  private mutating func push(node : CacheNode<T>, withKey key: Key) {
    if let existingNode = self.cache[key]  {
      // The existing CacheNode for key is returned, but discarded
      // The item wrapped in CacheNode is replaced by the incoming CacheNode
      // with matching key
      unlink(node: existingNode)
      cache.removeValue(forKey: key) // unnessesary, but illustrates the logic.
    }
    setHeadNode(node: node, withKey: key)
    let cacheSizeExceedsLimit = cache.count > limit
    if cacheSizeExceedsLimit { discardTail() }
  }
  
  /// Takes a given `CacheNode` and places it at the head of the linked list.
  ///
  /// - Parameters:
  ///   - node: A `CacheNode` to link into the head of the linked list
  ///   - key: The `key` used to reference and store a `CacheNode` in the cache
  /// - Note: This method manages the `head` and `tail` properties of the linked list
  private mutating func setHeadNode(node: CacheNode<T>, withKey key: Key) {
    // if node is tail, node.previous becomes the new tail
    if key == tail {
      if let previous = node.previous {
        tail = previous
      }
    }
    
    let unlinked = unlink(node: node)
    linkAsHead(node: unlinked, withKey: key)
    head = key
    if cache.count == 1 {
      tail = key
    }
  }
  
  /// Removes the `tail` node of the linked list from the linked list and the cache dictionary
  private mutating func discardTail() {
    guard let tailKey = tail
      else { preconditionFailure("tail key is not set.") }
    guard let tailNode = nodeFor(key: tailKey)
      else { preconditionFailure("tail node does not exist for key \(tailKey)") }
    tail = tailNode.previous
    
    unlink(node: tailNode)
    cache.removeValue(forKey: tailKey)
  }
  
  
  /// Takes an unlinked `CacheNode` and links it to the head of the linked list.
  ///
  /// - Parameters:
  ///   - node: A `CacheNode` to link into the head of the linked list
  ///   - key: The `key` used to reference and store a Node in the cache
  /// - Warning: Does not manage changing `head` or `tail`. Only acts on `CacheNode`s.
  /// - Note: This method manages the `CacheNode` properties, `previous` and `next`,
  ///         as well as updating the CacheNode in the cache dictionary.
  private mutating func linkAsHead(node: CacheNode<T>, withKey key: Key) {
    let message = "Only previously unlinked nodes may be added to the linked list. "
    assert(node.previous == .none, message + "CachedNode.previous expected to be nil ")
    assert(node.next     == .none, message + "CachedNode.next expected to be nil")
    var newHeadNode = node
    cache[key] = newHeadNode
    
    guard let pastHeadKey = head else { return }
    guard var pastHeadNode = nodeFor(key: pastHeadKey)
      else { preconditionFailure("Head Node key did not return an existing CacheNode from the cache as expected.") }
    
    newHeadNode.next  = pastHeadKey
    cache[key] = newHeadNode
    
    pastHeadNode.previous = key
    cache[pastHeadKey]    = pastHeadNode
  }
  
  /// Unlink `CacheNode` from its previous and next chain
  ///
  /// - Parameter node: A `CacheNode`
  /// - Returns: Incoming `CacheNode` with `previous` and `next` set to `nil`
  /// - Warning: Does not manage changing head or tail. Only acts on `CacheNode`s.
  @discardableResult
  private mutating func unlink(node: CacheNode<T>) -> CacheNode<T> {
    let linkedNode = node
    if let previousKey = linkedNode.previous,
      let previousNode = nodeFor(key: previousKey) {
      var node = previousNode
      node.next = linkedNode.next
      cache[previousKey] = node
    }
    if let nextKey = linkedNode.next,
      let nextNode = nodeFor(key: nextKey) {
      var node = nextNode
      node.previous = linkedNode.previous
      cache[nextKey] = node
    }
    
    var unlinkedNode = linkedNode
    unlinkedNode.previous = .none
    unlinkedNode.next     = .none
    return unlinkedNode
  }
}


typealias LimitedCache_Printing = KeyedCache
extension KeyedCache {
  
  internal func print() {
    var notDone = true
    guard let headKey = head else { return }
    guard let headNode = nodeFor(key: headKey) else { return }
    var currentNode = headNode
    var currentKey = headKey
    let describe = CacheNode<T>.describe
    Swift.print("head key: \(describe(self.head))")
    
    while (notDone) {
      print(node: currentNode, key: currentKey)
      if let nextKey = currentNode.next {
        if let nextNode = nodeFor(key: nextKey) {
          currentKey = nextKey
          currentNode = nextNode
        } else { notDone = false }
      } else { notDone = false }
    }
    
    Swift.print("tail key: \(describe(self.tail))")
    
  }
  
  private func print(node: CacheNode<T>, key: Key) {
    let describe = CacheNode<T>.describe
    Swift.print("node: \(key)    value: \(node.item)     previous: \(describe(node.previous))    next: \(describe(node.next))")
  }
}


