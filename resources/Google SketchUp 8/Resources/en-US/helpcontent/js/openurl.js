function modifyAnchor(anchorID, url)
{
  var anchorelement = document.getElementById(anchorID);
  anchorelement.href= 'http://sketchup.google.com/support/bin/answer.py?hl=en&answer=' + url;
  anchorelement.target = "_blank";
}

function replaceText(elementID, platform, childIndex, text)
{
  var lineItem = document.getElementById(elementID);
  var os = navigator.appVersion.indexOf(platform) != -1? 1 : 0;
  var child = lineItem.children(childIndex);
  if (os == 1) {
    child.innerText = text;
  }
}
