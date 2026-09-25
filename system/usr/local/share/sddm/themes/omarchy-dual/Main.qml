import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
  id: root
  width: 1280
  height: 720
  color: "#1a1b26"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property int sessionIndex: defaultSessionIndex()

  function sessionName(index) {
    if (index < 0 || index >= sessionModel.rowCount())
      return "Unknown"

    return (sessionModel.data(sessionModel.index(index, 0), Qt.DisplayRole) || "Unknown").toString()
  }

  function defaultSessionIndex() {
    if (sessionModel.lastIndex >= 0 && sessionModel.lastIndex < sessionModel.rowCount())
      return sessionModel.lastIndex

    for (var i = 0; i < sessionModel.rowCount(); i++) {
      if (sessionName(i).indexOf("Omarchy") !== -1)
        return i
    }

    return 0
  }

  function selectRelativeSession(offset) {
    var count = sessionModel.rowCount()
    if (count > 0)
      sessionIndex = (sessionIndex + offset + count) % count
  }

  function submit() {
    loginFailed = false
    sddm.login(currentUser, password.text, sessionIndex)
  }

  Connections {
    target: sddm

    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.forceActiveFocus()
    }

    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Column {
    anchors.centerIn: parent
    width: Math.min(620, root.width - 80)
    spacing: 28

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "OMARCHY"
      color: "#c0caf5"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 42
      font.bold: true
      font.letterSpacing: 8
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "Choose how this machine should start"
      color: "#7aa2f7"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 16
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 16

      Repeater {
        model: sessionModel

        Rectangle {
          required property int index
          required property string name
          width: 260
          height: 82
          radius: 5
          color: root.sessionIndex === index ? "#7aa2f7" : "#24283b"
          border.width: 2
          border.color: root.sessionIndex === index ? "#bb9af7" : "#414868"

          Text {
            anchors.centerIn: parent
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: name
            color: root.sessionIndex === index ? "#1a1b26" : "#c0caf5"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            font.bold: root.sessionIndex === index
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              root.sessionIndex = index
              password.forceActiveFocus()
            }
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.currentUser
      color: "#a9b1d6"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 16
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 420
      height: 52
      radius: 4
      color: "#24283b"
      border.width: 2
      border.color: root.loginFailed ? "#f7768e" : password.activeFocus ? "#7aa2f7" : "#414868"

      TextInput {
        id: password
        anchors.fill: parent
        anchors.margins: 14
        verticalAlignment: TextInput.AlignVCenter
        echoMode: TextInput.Password
        passwordCharacter: "\u2022"
        color: "#c0caf5"
        selectionColor: "#7aa2f7"
        selectedTextColor: "#1a1b26"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        focus: true

        onTextChanged: root.loginFailed = false

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit()
            event.accepted = true
          } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) {
            root.selectRelativeSession(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.selectRelativeSession(-1)
            event.accepted = true
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.loginFailed ? "Authentication failed" : "Enter: login    Tab / arrows: change session"
      color: root.loginFailed ? "#f7768e" : "#565f89"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 14
    }
  }

  Component.onCompleted: password.forceActiveFocus()
}
