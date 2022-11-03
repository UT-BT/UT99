class UWindowConsoleClientWindow extends UWindowDialogClientWindow config(user);

var UWindowConsoleTextAreaControl TextArea;
var UWindowEditControl	EditControl;

var config string History[32];

function Created()
{
	local int i;
	local UWindowEditBoxHistory CurrentHistory;

	TextArea = UWindowConsoleTextAreaControl(CreateWindow(class'UWindowConsoleTextAreaControl', 0, 0, WinWidth, WinHeight));
	EditControl = UWindowEditControl(CreateControl(class'UWindowEditControl', 0, WinHeight-16, WinWidth, 16));
	EditControl.SetFont(F_Normal);
	EditControl.SetNumericOnly(False);
	EditControl.SetMaxLength(400);
	EditControl.SetHistory(True);

	for (i = ArrayCount(History) - 1; i >= 0; i--)
	{
		if (History[i] == "") continue;
		CurrentHistory = UWindowEditBoxHistory(EditControl.EditBox.HistoryList.Insert(class'UWindowEditBoxHistory'));
		CurrentHistory.HistoryText = History[i];
	}
	EditControl.EditBox.CurrentHistory = EditControl.EditBox.HistoryList;
}

function Notify(UWindowDialogControl C, byte E)
{
	local string s;
	local int i;
	local UWindowEditBoxHistory CurrentHistory;

	Super.Notify(C, E);

	switch(E)
	{
	case DE_EnterPressed:
		switch(C)
		{
		case EditControl:
			if(EditControl.GetValue() != "")
			{
				CurrentHistory = EditControl.EditBox.HistoryList;
				for (i = 0; i < ArrayCount(History); i++)
				{
					if (CurrentHistory.Next == None)
						History[i] = "";
					else
					{
						CurrentHistory = UWindowEditBoxHistory(CurrentHistory.Next);
						History[i] = CurrentHistory.HistoryText;
					}
				}
				SaveConfig();				

				s = EditControl.GetValue();
				Root.Console.Message( None, "> "$s, 'Console' );
				EditControl.Clear();
				if( !Root.Console.ConsoleCommand( s ) )
					Root.Console.Message( None, Localize("Errors","Exec","Core"), 'Console' );
			}
			break;
		}
		break;
	case DE_WheelUpPressed:
		switch(C)
		{
		case EditControl:
			TextArea.VertSB.Scroll(-1);
			break;
		}
		break;
	case DE_WheelDownPressed:
		switch(C)
		{
		case EditControl:
			TextArea.VertSB.Scroll(1);
			break;
		}
		break;
	}
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);

	EditControl.SetSize(WinWidth, 17);
	EditControl.WinLeft = 0;
	EditControl.WinTop = WinHeight - EditControl.WinHeight;
	EditControl.EditBoxWidth = WinWidth;

	TextArea.SetSize(WinWidth, WinHeight - EditControl.WinHeight);
}

function Paint(Canvas C, float X, float Y)
{
	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'BlackTexture');
}

defaultproperties
{
      TextArea=None
      EditControl=None
      History(0)=""
      History(1)=""
      History(2)=""
      History(3)=""
      History(4)=""
      History(5)=""
      History(6)=""
      History(7)=""
      History(8)=""
      History(9)=""
      History(10)=""
      History(11)=""
      History(12)=""
      History(13)=""
      History(14)=""
      History(15)=""
      History(16)=""
      History(17)=""
      History(18)=""
      History(19)=""
      History(20)=""
      History(21)=""
      History(22)=""
      History(23)=""
      History(24)=""
      History(25)=""
      History(26)=""
      History(27)=""
      History(28)=""
      History(29)=""
      History(30)=""
      History(31)=""
}
