# View Controller Notes
## Level Selection Scene
### Buttons
The buttons are each given number respectively (Level 1: 1, Level 2: 2, etc). 
These tag numbers are used to determine what level the player/user is on and 
used to determine difficutly, etc.  
Example:
ViewController
```
override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
 if (segue.identifier == "firstIdentifier") {
        var VC2 : VC2 = segue.destinationViewController as VC2
        VC2.buttonTag = sender.tag

 }
 if (segue.identifier == "secondIdentifier") {
    var VC2 : VC2 = segue.destinationViewController as VC2
        VC2.buttonTag = sender.tag
 }
}
```
ViewController2
```
var buttonTag = 0
```
ViewController2.segueHandling
```
if buttonTag == 1 {
  //segue caused by button1 of VC1
}
else
if buttonTag == 2 {
  //segue caused by button2 of VC1
}
else {
  //segue caused by something else
}
```
[Reference](http://stackoverflow.com/questions/29218345/multiple-segues-to-the-same-view-controller)
Also can be used to pass back to unlock the 
next level for the user.