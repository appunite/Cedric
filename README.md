# Cedric

## Who am I? 

Hey! My name is **Cedric**, I was born to help iOS / macOS developers with a quite difficult task that is downloading files. 

## What are my responsibilities? 

Behind just downloading files I'm able to perorm operations like:
- notify about updates via **MulticastDelegate**
- perorm operations in a **serial** or **parallel (with limit)** options
- perform browser-like download with **always creating new files**
- **reuse** already downloaded files for the same resource 
- notify that all resources from queue are downloaded 
- apply attributes to files specified in resource

## Example usage 

```swift
let resource = DownloadResource(id: asset.id, source: asset.url, destinationName: asset.name + ".mp3", mode: .notDownloadIfExists)
try cedric.enqueueDownload(forResource: resource) 

func cedric(_ cedric: Cedric, didFinishDownloadingResource resource: DownloadResource, toFile file: DownloadedFile) {
   do { 
      let url = try file.url()
      guard let image = UIImage(contentsOfFile: url.path) else { return }	
      fileImageView.image = image
   } catch let error {
      ...
   }
}
```

## Cedric Configuration Modes

As I've mentioned, I'm able to work in different modes with allowing for serial or parallel downloading. 

Using serial mode (downloading files in the queue one by one):

```swift
let configuration = CedricConfiguration(mode: .serial)
return Cedric(configuration: configuration)
```

<img src="Resources/cedric-serial.gif" width="300" height="500" />

Using parallel mode (with concurent 3 tasks): 

```swift
let configuration = CedricConfiguration(mode: .parallel(max: 3))
return Cedric(configuration: configuration)
```

<img src="Resources/cedric-parallel.gif" width="300" height="500" />

### Carthage

Add the following entry in your Cartfile:

```
github "appunite/Cedric"
```

Then run `carthage update`.

### Cocoapods

Add the following entry in your Podfile

```
pod 'Cedric'
```

Then run `pod install`.

### Contribution

Project is created and maintened by **Szymon Mrozek**.

We could use your help with reporting or fixing bugs. We would also like to hear from you about feature suggestions. If you have an idea how to make Cedric better you are welcome to send us a Pull Request.

### License

Cedric is released under an MIT license. See [License.md](LICENSE.md) for more information.

