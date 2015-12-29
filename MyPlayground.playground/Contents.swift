//: Playground - noun: a place where people can play

import UIKit

let url = NSURL(string: "file:///Users/DanielW/participants.csv")!

let dir = url.URLByDeletingLastPathComponent!
let ext = url.pathExtension!
let nameWithoutExt = url.URLByDeletingPathExtension!.lastPathComponent!
let newFileName = nameWithoutExt + "_copy"
let newFileURL = dir.URLByAppendingPathComponent(newFileName).URLByAppendingPathExtension(ext)