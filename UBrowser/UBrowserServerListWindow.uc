class UBrowserServerListWindow extends UWindowPageWindow
	PerObjectConfig;

var config string				ServerListTitle;	// Non-localized page title
var config string				ListFactories[10];
var config string				URLAppend;
var config int					AutoRefreshTime;
var config bool					bNoAutoSort;
var config bool					bHidden;
var config bool					bFallbackFactories;

var config string				HiddenTypes[256];

var config string				FilterString;
var string						FilterStringCaps;
var config bool					bNoEmpty;
var config bool					bNoFull;
var config bool					bNoLocked;

var string						ServerListClassName;
var class<UBrowserServerList>	ServerListClass;

var UBrowserServerList			PingedList;
var UBrowserServerList			HiddenList;
var UBrowserServerList			UnpingedList;

var UBrowserServerListFactory	Factories[10];
var int							QueryDone[10];
var UBrowserServerGrid			Grid;
var string						GridClass;
var float						TimeElapsed;
var bool						bPingSuspend;
var bool						bPingResume;
var bool						bPingResumeIntial;
var bool						bNoSort;
var bool						bSuspendPingOnClose;
var UBrowserSubsetList			SubsetList;
var UBrowserSupersetList		SupersetList;
var class<UBrowserRightClickMenu>	RightClickMenuClass;
var bool						bShowFailedServers;
var bool						bHadInitialRefresh;
var int							FallbackFactory;

var UWindowEditControl			Filter;
var UWindowCheckbox				Empty;
var UWindowCheckbox				Full;
var UWindowCheckbox				Locked;

var UWindowHSplitter			HSplitter;
var UBrowserTypesGrid			TypesGrid;
var UBrowserTypesList			TypesList;

var UWindowVSplitter			VSplitter;
var UBrowserInfoWindow			InfoWindow;
var UBrowserInfoClientWindow	InfoClient;
var UBrowserServerList			InfoItem;
var localized string			InfoName;

const MinHeightForSplitter = 384;
const GapTop = 30;

var() Color						WhiteColor;

var localized string			PlayerCountLeader;
var localized string			ServerCountLeader;

var() localized string			FilterText;
var() localized string			FilterHelp;
var() localized string			EmptyText;
var() localized string			EmptyHelp;
var() localized string			FullText;
var() localized string			FullHelp;
var() localized string			LockedText;
var() localized string			LockedHelp;

// Status info
enum EPingState
{
	PS_QueryServer,
	PS_QueryFailed,
	PS_Pinging,
	PS_RePinging,
	PS_Done
};

var localized string			PlayerCountName;
var localized string			ServerCountName;
var	localized string			QueryServerText;
var	localized string			QueryFailedText;
var	localized string			PingingText;
var	localized string			CompleteText;

var string						ErrorString;
var EPingState					PingState;

function WindowShown()
{
	local UBrowserSupersetList l;

	Super.WindowShown();
	if(VSplitter.bWindowVisible)
	{
		if(UWindowVSplitter(InfoClient.ParentWindow) != None)
			VSplitter.SplitPos = UWindowVSplitter(InfoClient.ParentWindow).SplitPos;

		InfoClient.SetParent(VSplitter);
	}

	InfoClient.Server = InfoItem;
	if(InfoItem != None)
		InfoWindow.WindowTitle = InfoName$" - "$InfoItem.HostName;
	else
		InfoWindow.WindowTitle = InfoName;

	ResumePinging();

	for(l = UBrowserSupersetList(SupersetList.Next); l != None; l = UBrowserSupersetList(l.Next))
		l.SuperSetWindow.ResumePinging();
}

function WindowHidden()
{
	local UBrowserSupersetList l;

	Super.WindowHidden();
	SuspendPinging();

	for(l = UBrowserSupersetList(SupersetList.Next); l != None; l = UBrowserSupersetList(l.Next))
		l.SuperSetWindow.SuspendPinging();
}

function SuspendPinging()
{
	if(bSuspendPingOnClose)
		bPingSuspend = True;
}

function ResumePinging()
{
	if(!bHadInitialRefresh)
		Refresh(False, True);	

	bPingSuspend = False;
	if(bPingResume)
	{
		bPingResume = False;
		UnpingedList.PingNext(bPingResumeIntial, bNoSort);
	}
}

function SaveFilters()
{
	local int i;
	local UBrowserTypesList RulesList;

	for(RulesList = UBrowserTypesList(TypesList.Next); RulesList != None; RulesList = UBrowserTypesList(RulesList.Next))
		if(!RulesList.bShow)
		{
			HiddenTypes[i++] = RulesList.Type;
			if (i == ArrayCount(HiddenTypes))
				break;
		}

	for(i = i; i < ArrayCount(HiddenTypes); i++)
		HiddenTypes[i] = "";

	FilterString = Filter.GetValue();
	bNoEmpty = !Empty.bChecked;
	bNoFull = !Full.bChecked;
	bNoLocked = !Locked.bChecked;

	FilterStringCaps = Caps(FilterString);

	SaveConfig();
}

function Created()
{
	local Class<UBrowserServerGrid> C;
	local int i;
	local UBrowserTypesList RulesList;
	
	ServerListClass = class<UBrowserServerList>(DynamicLoadObject(ServerListClassName, class'Class'));
	C = class<UBrowserServerGrid>(DynamicLoadObject(GridClass, class'Class'));
	Grid = UBrowserServerGrid(CreateWindow(C, 0, 0, WinWidth, WinHeight));
	Grid.SetAcceptsFocus();

	SubsetList = new class'UBrowserSubsetList';
	SubsetList.SetupSentinel();

	SupersetList = new class'UBrowserSupersetList';
	SupersetList.SetupSentinel();

	TypesList = New(None) class'UBrowserTypesList';
	TypesList.SetupSentinel(true);

	for(i = 0; i < ArrayCount(HiddenTypes); i++)
	{
		if (HiddenTypes[i] != "")
		{
			RulesList = new(None) class'UBrowserTypesList';
			RulesList.Type = HiddenTypes[i];
			TypesList.AppendItem(RulesList);
		}
	}

	Empty = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 0, 0, WinWidth, 1));
	Empty.bChecked = !bNoEmpty;
	Empty.SetText(EmptyText);
	Empty.SetHelpText(EmptyHelp);
	Empty.SetFont(F_Normal);
	Empty.Align = TA_Right;
	Empty.TextColor = WhiteColor;

	Full = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 0, 0, WinWidth, 1));
	Full.bChecked = !bNoFull;
	Full.SetText(FullText);
	Full.SetHelpText(FullHelp);
	Full.SetFont(F_Normal);
	Full.Align = TA_Right;
	Full.TextColor = WhiteColor;

	Locked = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 0, 0, WinWidth, 1));
	Locked.bChecked = !bNoLocked;
	Locked.SetText(LockedText);
	Locked.SetHelpText(LockedHelp);
	Locked.SetFont(F_Normal);
	Locked.Align = TA_Right;
	Locked.TextColor = WhiteColor;

	Filter = UWindowEditControl(CreateControl(class'UWindowEditControl', 0, 0, WinWidth, 1));
	Filter.SetText(FilterText);
	Filter.SetHelpText(FilterHelp);
	Filter.SetFont(F_Normal);
	Filter.Align = TA_Left;
	Filter.TextColor = WhiteColor;
	Filter.EditAreaDrawX = 40;
	Filter.SetValue(FilterString); // must be last

	TypesGrid = UBrowserTypesGrid(CreateWindow(class'UBrowserTypesGrid', 0, 0, WinWidth, WinHeight));
	TypesGrid.SetAcceptsFocus();

	HSplitter = UWindowHSplitter(CreateWindow(class'UWindowHSplitter', 0, 0, WinWidth, WinHeight));
	TypesGrid.SetParent(HSplitter);
	Grid.SetParent(HSplitter);
	HSplitter.LeftClientWindow = TypesGrid;
	HSplitter.RightClientWindow = Grid;
	HSplitter.MinWinWidth = 60;
	HSplitter.bRightGrow = true;
	HSplitter.OldWinWidth = HSplitter.WinWidth;
	HSplitter.SplitPos = 180;
	HSplitter.SetAcceptsFocus();
	HSplitter.ShowWindow();

	VSplitter = UWindowVSplitter(CreateWindow(class'UWindowVSplitter', 0, 0, WinWidth, WinHeight));
	VSplitter.SetAcceptsFocus();
	VSplitter.MinWinHeight = 60;
	VSplitter.HideWindow();
	InfoWindow = UBrowserMainClientWindow(GetParent(class'UBrowserMainClientWindow')).InfoWindow;
	InfoClient = UBrowserInfoClientWindow(InfoWindow.ClientArea);

	ShowInfoArea(True, Root.WinHeight < MinHeightForSplitter);
}

function ShowInfoArea(bool bShow, optional bool bFloating, optional bool bNoActivate)
{
	if(bShow)
	{
		if(bFloating)
		{
			VSplitter.HideWindow();
			VSplitter.TopClientWindow = None;
			VSplitter.BottomClientWindow = None;
			InfoClient.SetParent(InfoWindow);
			HSplitter.SetParent(Self);
			HSplitter.WinTop = GapTop;
			HSplitter.SetSize(WinWidth, WinHeight - GapTop);
			if(!InfoWindow.bWindowVisible)
				InfoWindow.ShowWindow();
			if(!bNoActivate)
				InfoWindow.BringToFront();
		}
		else
		{
			InfoWindow.HideWindow();
			VSplitter.ShowWindow();
			VSplitter.WinTop = GapTop;
			VSplitter.SetSize(WinWidth, WinHeight - GapTop);
			HSplitter.SetParent(VSplitter);
			HSplitter.WinTop = 0;
			InfoClient.SetParent(VSplitter);
			VSplitter.TopClientWindow = HSplitter;
			VSplitter.BottomClientWindow = InfoClient;
		}
	}
	else
	{
		InfoWindow.HideWindow();
		VSplitter.HideWindow();
		VSplitter.TopClientWindow = None;
		VSplitter.BottomClientWindow = None;
		InfoClient.SetParent(InfoWindow);
		HSplitter.SetParent(Self);
		HSplitter.WinTop = GapTop;
		HSplitter.SetSize(WinWidth, WinHeight - GapTop);
	}
}

function AutoInfo(UBrowserServerList I)
{
	if(Root.WinHeight >= MinHeightForSplitter || InfoWindow.bWindowVisible)
		ShowInfo(I, True);
}

function ShowInfo(UBrowserServerList I, optional bool bAutoInfo)
{
	if(I == None) return;
	ShowInfoArea(True, Root.WinHeight < MinHeightForSplitter, bAutoInfo);

	InfoItem = I;
	InfoClient.Server = InfoItem;
	InfoWindow.WindowTitle = InfoName$" - "$InfoItem.HostName;
	I.ServerStatus();
}

function ResolutionChanged(float W, float H)
{
	if(Root.WinHeight >= MinHeightForSplitter)
		ShowInfoArea(True, False);
	else
		ShowInfoArea(True, True);
	
	if(InfoWindow != None)
		InfoWindow.ResolutionChanged(W, H);

	Super.ResolutionChanged(W, H);
}

function Resized()
{
	Super.Resized();
	if(VSplitter.bWindowVisible)
	{
		VSplitter.SetSize(WinWidth, WinHeight);
		VSplitter.OldWinHeight = VSplitter.WinHeight;
		VSplitter.SplitPos = VSplitter.WinHeight - Min(VSplitter.WinHeight / 1.5, 600);
	}
	else
		Grid.SetSize(WinWidth, WinHeight);
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	switch(E)
	{
	case DE_Change:
		switch(C)
		{
		case Filter:
		case Empty:
		case Full:
		case Locked:
			SaveFilters();
			break;
		}
		break;
	}
}

function AddSubset(UBrowserSubsetFact Subset)
{
	local UBrowserSubsetList l;

	for(l = UBrowserSubsetList(SubsetList.Next); l != None; l = UBrowserSubsetList(l.Next))
		if(l.SubsetFactory == Subset)
			return;
	
	l = UBrowserSubsetList(SubsetList.Append(class'UBrowserSubsetList'));
	l.SubsetFactory = Subset;
}

function AddSuperSet(UBrowserServerListWindow Superset)
{
	local UBrowserSupersetList l;

	for(l = UBrowserSupersetList(SupersetList.Next); l != None; l = UBrowserSupersetList(l.Next))
		if(l.SupersetWindow == Superset)
			return;
	
	l = UBrowserSupersetList(SupersetList.Append(class'UBrowserSupersetList'));
	l.SupersetWindow = Superset;
}

function RemoveSubset(UBrowserSubsetFact Subset)
{
	local UBrowserSubsetList l;

	for(l = UBrowserSubsetList(SubsetList.Next); l != None; l = UBrowserSubsetList(l.Next))
		if(l.SubsetFactory == Subset)
			l.Remove();
}

function RemoveSuperset(UBrowserServerListWindow Superset)
{
	local UBrowserSupersetList l;

	for(l = UBrowserSupersetList(SupersetList.Next); l != None; l = UBrowserSupersetList(l.Next))
		if(l.SupersetWindow == Superset)
			l.Remove();
}

function UBrowserServerList AddFavorite(UBrowserServerList Server)
{
	return UBrowserServerListWindow(UBrowserMainClientWindow(GetParent(class'UBrowserMainClientWindow')).Favorites.Page).AddFavorite(Server);
}

function Refresh(optional bool bBySuperset, optional bool bInitial, optional bool bSaveExistingList, optional bool bInNoSort)
{
	bHadInitialRefresh = True;

	if(!bSaveExistingList)
	{
		InfoItem = None;
		InfoClient.Server = None;
	}

	if(!bSaveExistingList && PingedList != None)
	{
		PingedList.DestroyList();
		PingedList = None;
		Grid.SelectedServer = None;

		HiddenList.DestroyList();
		HiddenList = None;
	}

	if(PingedList == None)
	{
		PingedList=New ServerListClass;
		PingedList.Owner = Self;
		PingedList.SetupSentinel(True);
		PingedList.bSuspendableSort = True;

		HiddenList=New ServerListClass;
		HiddenList.Owner = Self;
		HiddenList.SetupSentinel();
	}
	else
	{
		PingedList.AppendListCopy(HiddenList);
		HiddenList.Clear();
		TagServersAsOld();
	}

	if(UnpingedList != None)
		UnpingedList.DestroyList();
	
	if(!bSaveExistingList)
	{
		UnpingedList = New ServerListClass;
		UnpingedList.Owner = Self;
		UnpingedList.SetupSentinel(False);
	}

	PingState = PS_QueryServer;
	ShutdownFactories(bBySuperset);
	CreateFactories(bSaveExistingList);
	Query(bBySuperset, bInitial, bInNoSort);

	if(!bInitial)
		RefreshSubsets();
}

function TagServersAsOld()
{
	local UBrowserServerList l;

	for(l = UBrowserServerList(PingedList.Next);l != None;l = UBrowserServerList(l.Next)) 
		l.bOldServer = True;
}

function RemoveOldServers()
{
	local UBrowserServerList l, n;

	l = UBrowserServerList(PingedList.Next);
	while(l != None) 
	{
		n = UBrowserServerList(l.Next);

		if(l.bOldServer)
		{
			if(Grid.SelectedServer == l)
				Grid.SelectedServer = n;

			l.Remove();
		}
		l = n;
	}
}

function RefreshSubsets()
{
	local UBrowserSubsetList l, NextSubset;

	for(l = UBrowserSubsetList(SubsetList.Next); l != None; l = UBrowserSubsetList(l.Next))
		l.bOldElement = True;

	l = UBrowserSubsetList(SubsetList.Next);
	while(l != None && l.bOldElement)
	{
		NextSubset = UBrowserSubsetList(l.Next);
		l.SubsetFactory.Owner.Owner.Refresh(True);
		l = NextSubset;
	}
}

function RePing()
{
	PingState = PS_RePinging;
	PingedList.InvalidatePings();
	PingedList.PingServers(True, False);
}

function QueryFinished(UBrowserServerListFactory Fact, bool bSuccess, optional string ErrorMsg)
{
	local int i;
	local bool bDone;

	bDone = True;
	for(i=0;i<10;i++)
	{
		if(Factories[i] != None)
		{
			if(Factories[i] == Fact)
				QueryDone[i] = 1;
			if(QueryDone[i] == 0)
				bDone = False;
		}
	}

	if(!bSuccess)
	{
		PingState = PS_QueryFailed;
		ErrorString = ErrorMsg;

		// don't ping and report success if we have no servers.
		if(bDone && UnpingedList.Count() == 0)
		{
			if( bFallbackFactories )
			{
				FallbackFactory++;
				if( ListFactories[FallbackFactory] != "" )
					Refresh();	// try the next fallback master server
				else
					FallbackFactory = 0;
			}
			return;
		}
	}
	else
		ErrorString = "";

	if(bDone)
	{
		RemoveOldServers();

		PingState = PS_Pinging;
		if(!bNoSort && !Fact.bIncrementalPing)
			PingedList.Sort();
		UnpingedList.PingServers(True, bNoSort || Fact.bIncrementalPing);
	}
}

function PingFinished()
{
	PingState = PS_Done;
}

function CreateFactories(bool bUsePingedList)
{
	local int i;

	for(i=0;i<10;i++)
	{
		if(ListFactories[i] == "")
			break;
		if(!bFallbackFactories || FallbackFactory == i)
		{
			Factories[i] = UBrowserServerListFactory(BuildObjectWithProperties(ListFactories[i]));
			
			Factories[i].PingedList = PingedList;
			Factories[i].UnpingedList = UnpingedList;
		
			if(bUsePingedList)
				Factories[i].Owner = PingedList;
			else
				Factories[i].Owner = UnpingedList;
		}
		QueryDone[i] = 0;
	}	
}

function ShutdownFactories(optional bool bBySuperset)
{
	local int i;

	for(i=0;i<10;i++)
	{
		if(Factories[i] != None) 
		{
			Factories[i].Shutdown(bBySuperset);
			Factories[i] = None;
		}
	}	
}

function Query(optional bool bBySuperset, optional bool bInitial, optional bool bInNoSort)
{
	local int i;

	bNoSort = bInNoSort;

	// Query all our factories
	for(i=0;i<10;i++)
	{
		if(Factories[i] != None)
			Factories[i].Query(bBySuperset, bInitial);
	}
}

function Paint(Canvas C, float X, float Y)
{
	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'BlackTexture');
}

function Tick(float Delta)
{
	PingedList.Tick(Delta);

	if(PingedList.bNeedUpdateCount)
	{
		PingedList.UpdateServerCount();
		PingedList.bNeedUpdateCount = False;
	}

	// AutoRefresh local servers
	if(AutoRefreshTime > 0)
	{
		TimeElapsed += Delta;
		
		if(TimeElapsed > AutoRefreshTime)
		{
			TimeElapsed = 0;
			Refresh(,,True, bNoAutoSort);
		}
	}	
}

function BeforePaint(Canvas C, float X, float Y)
{
	local UBrowserMainWindow W;
	local UBrowserSupersetList l;
	local EPingState P;
	local int PercentComplete;
	local int TotalReturnedServers;
	local string E;
	local int TotalServers;
	local int PingedServers;
	local int MyServers;
	local int ControlTop, ControlLeft, ContolRight;

	const ControlHeight = 18;

	Super.BeforePaint(C, X, Y);

	ControlTop = (GapTop - ControlHeight)/2;
	ControlLeft = ControlHeight/2;
	ContolRight = ControlLeft;
	
	Locked.SetSize(50, ControlHeight);
	Locked.WinTop = ControlTop;
	Locked.WinLeft = WinWidth - Locked.WinWidth - ContolRight;
	ContolRight += Locked.WinWidth + ControlHeight;

	Full.SetSize(40, ControlHeight);
	Full.WinTop = ControlTop;
	Full.WinLeft = WinWidth - Full.WinWidth - ContolRight;
	ContolRight += Full.WinWidth + ControlHeight;

	Empty.SetSize(50, ControlHeight);
	Empty.WinTop = ControlTop;
	Empty.WinLeft = WinWidth - Empty.WinWidth - ContolRight;
	ContolRight += Empty.WinWidth + ControlHeight;

	Filter.SetSize(WinWidth - ContolRight - ControlLeft, ControlHeight);
	Filter.WinTop = ControlTop;
	Filter.WinLeft = ControlLeft;
	Filter.EditBoxWidth = Filter.WinWidth - Filter.EditAreaDrawX;

	W = UBrowserMainWindow(GetParent(class'UBrowserMainWindow'));
	l = UBrowserSupersetList(SupersetList.Next);

	if(l != None && PingState != PS_RePinging)
	{
		P = l.SupersetWindow.PingState;
		PingState = P;

		if(P == PS_QueryServer)
			TotalReturnedServers = l.SupersetWindow.UnpingedList.Count();

		PingedServers = l.SupersetWindow.PingedList.Count();
		TotalServers = l.SupersetWindow.UnpingedList.Count() + PingedServers;
		MyServers = PingedList.Count();
	
		E = l.SupersetWindow.ErrorString;
	}
	else
	{
		P = PingState;
		if(P == PS_QueryServer)
			TotalReturnedServers = UnpingedList.Count();

		PingedServers = PingedList.Count();
		TotalServers = UnpingedList.Count() + PingedServers;
		MyServers = PingedList.Count();

		E = ErrorString;
	}

	if(TotalServers > 0)
		PercentComplete = PingedServers*100.0/TotalServers;

	switch(P)
	{
	case PS_QueryServer:
		if(TotalReturnedServers > 0)
			W.DefaultStatusBarText(QueryServerText$" ("$ServerCountLeader$TotalReturnedServers$" "$ServerCountName$")");
		else
			W.DefaultStatusBarText(QueryServerText);
		break;
	case PS_QueryFailed:
		W.DefaultStatusBarText(QueryFailedText$E);
		break;
	case PS_Pinging:
	case PS_RePinging:
		W.DefaultStatusBarText(PingingText$" "$PercentComplete$"% "$CompleteText$". "$ServerCountLeader$MyServers$" "$ServerCountName$", "$PlayerCountLeader$PingedList.TotalPlayers$" "$PlayerCountName);
		break;
	case PS_Done:
		W.DefaultStatusBarText(ServerCountLeader$MyServers$" "$ServerCountName$", "$PlayerCountLeader$PingedList.TotalPlayers$" "$PlayerCountName);
		break;
	}

	ApplyTypeFilter(HiddenList, PingedList);
	ApplyTypeFilter(PingedList, HiddenList);
}

function ApplyTypeFilter(UBrowserServerList From, UBrowserServerList To)
{
	local UBrowserServerList List, Item;
	local UBrowserTypesList  RulesList;
	local bool bShow, bSkip;
	local string Chr13;

	Chr13 = Chr(13);
	if(From != HiddenList)
		bShow = true;
	else
		for(RulesList = UBrowserTypesList(TypesList.Next); RulesList != None; RulesList = UBrowserTypesList(RulesList.Next))
			RulesList.iCount = 0;
	List = UBrowserServerList(From.Next);
	while(List != None)
	{
		Item = List;
		List = UBrowserServerList(List.Next);

		bSkip = false;
		if (bNoEmpty && Item.NumPlayers == 0)
			bSkip = true;
		if (!bSkip && bNoFull && Item.NumPlayers == Item.MaxPlayers)
			bSkip = true;
		if (!bSkip && bNoLocked && Item.bLocked)
			bSkip = true;
		if (!bSkip && FilterStringCaps != "" && InStr(Caps(
			Item.HostName $ Chr13 $ 
			Item.MapName $ Chr13 $ 
			Item.MapTitle $ Chr13 $ 
			Item.MapDisplayName $ Chr13 $
			Item.GameType $ Chr13 $
			Item.GameMode $ Chr13
			) $ Item.FilterString, FilterStringCaps) == -1)
			bSkip = true;
		if(bSkip)
		{
			if(bShow)
			{
				Item.Remove();
				To.AppendItem(Item);
			}
			goto NextServer;
		}

		for(RulesList = UBrowserTypesList(TypesList.Next); RulesList != None; RulesList = UBrowserTypesList(RulesList.Next))
		{
			if(RulesList.Type ~= Item.GameType)
			{
				if(RulesList.bShow == bShow)
					RulesList.iCount++;
				else					
				{
					Item.Remove();
					To.AppendItem(Item);
				}

				goto NextServer; // Rule already exists
			}
		}

		// Add the rule
		RulesList = new(None) class'UBrowserTypesList';
		RulesList.Type = Item.GameType;
		RulesList.bShow = True;
		TypesList.AppendItem(RulesList);
		if(From == HiddenList)
		{
			Item.Remove();
			To.AppendItem(Item);
		}
		NextServer:
	}
}

defaultproperties
{
      ServerListTitle=""
      ListFactories(0)=""
      ListFactories(1)=""
      ListFactories(2)=""
      ListFactories(3)=""
      ListFactories(4)=""
      ListFactories(5)=""
      ListFactories(6)=""
      ListFactories(7)=""
      ListFactories(8)=""
      ListFactories(9)=""
      URLAppend=""
      AutoRefreshTime=0
      bNoAutoSort=False
      bHidden=False
      bFallbackFactories=False
      HiddenTypes(0)=""
      HiddenTypes(1)=""
      HiddenTypes(2)=""
      HiddenTypes(3)=""
      HiddenTypes(4)=""
      HiddenTypes(5)=""
      HiddenTypes(6)=""
      HiddenTypes(7)=""
      HiddenTypes(8)=""
      HiddenTypes(9)=""
      HiddenTypes(10)=""
      HiddenTypes(11)=""
      HiddenTypes(12)=""
      HiddenTypes(13)=""
      HiddenTypes(14)=""
      HiddenTypes(15)=""
      HiddenTypes(16)=""
      HiddenTypes(17)=""
      HiddenTypes(18)=""
      HiddenTypes(19)=""
      HiddenTypes(20)=""
      HiddenTypes(21)=""
      HiddenTypes(22)=""
      HiddenTypes(23)=""
      HiddenTypes(24)=""
      HiddenTypes(25)=""
      HiddenTypes(26)=""
      HiddenTypes(27)=""
      HiddenTypes(28)=""
      HiddenTypes(29)=""
      HiddenTypes(30)=""
      HiddenTypes(31)=""
      HiddenTypes(32)=""
      HiddenTypes(33)=""
      HiddenTypes(34)=""
      HiddenTypes(35)=""
      HiddenTypes(36)=""
      HiddenTypes(37)=""
      HiddenTypes(38)=""
      HiddenTypes(39)=""
      HiddenTypes(40)=""
      HiddenTypes(41)=""
      HiddenTypes(42)=""
      HiddenTypes(43)=""
      HiddenTypes(44)=""
      HiddenTypes(45)=""
      HiddenTypes(46)=""
      HiddenTypes(47)=""
      HiddenTypes(48)=""
      HiddenTypes(49)=""
      HiddenTypes(50)=""
      HiddenTypes(51)=""
      HiddenTypes(52)=""
      HiddenTypes(53)=""
      HiddenTypes(54)=""
      HiddenTypes(55)=""
      HiddenTypes(56)=""
      HiddenTypes(57)=""
      HiddenTypes(58)=""
      HiddenTypes(59)=""
      HiddenTypes(60)=""
      HiddenTypes(61)=""
      HiddenTypes(62)=""
      HiddenTypes(63)=""
      HiddenTypes(64)=""
      HiddenTypes(65)=""
      HiddenTypes(66)=""
      HiddenTypes(67)=""
      HiddenTypes(68)=""
      HiddenTypes(69)=""
      HiddenTypes(70)=""
      HiddenTypes(71)=""
      HiddenTypes(72)=""
      HiddenTypes(73)=""
      HiddenTypes(74)=""
      HiddenTypes(75)=""
      HiddenTypes(76)=""
      HiddenTypes(77)=""
      HiddenTypes(78)=""
      HiddenTypes(79)=""
      HiddenTypes(80)=""
      HiddenTypes(81)=""
      HiddenTypes(82)=""
      HiddenTypes(83)=""
      HiddenTypes(84)=""
      HiddenTypes(85)=""
      HiddenTypes(86)=""
      HiddenTypes(87)=""
      HiddenTypes(88)=""
      HiddenTypes(89)=""
      HiddenTypes(90)=""
      HiddenTypes(91)=""
      HiddenTypes(92)=""
      HiddenTypes(93)=""
      HiddenTypes(94)=""
      HiddenTypes(95)=""
      HiddenTypes(96)=""
      HiddenTypes(97)=""
      HiddenTypes(98)=""
      HiddenTypes(99)=""
      HiddenTypes(100)=""
      HiddenTypes(101)=""
      HiddenTypes(102)=""
      HiddenTypes(103)=""
      HiddenTypes(104)=""
      HiddenTypes(105)=""
      HiddenTypes(106)=""
      HiddenTypes(107)=""
      HiddenTypes(108)=""
      HiddenTypes(109)=""
      HiddenTypes(110)=""
      HiddenTypes(111)=""
      HiddenTypes(112)=""
      HiddenTypes(113)=""
      HiddenTypes(114)=""
      HiddenTypes(115)=""
      HiddenTypes(116)=""
      HiddenTypes(117)=""
      HiddenTypes(118)=""
      HiddenTypes(119)=""
      HiddenTypes(120)=""
      HiddenTypes(121)=""
      HiddenTypes(122)=""
      HiddenTypes(123)=""
      HiddenTypes(124)=""
      HiddenTypes(125)=""
      HiddenTypes(126)=""
      HiddenTypes(127)=""
      HiddenTypes(128)=""
      HiddenTypes(129)=""
      HiddenTypes(130)=""
      HiddenTypes(131)=""
      HiddenTypes(132)=""
      HiddenTypes(133)=""
      HiddenTypes(134)=""
      HiddenTypes(135)=""
      HiddenTypes(136)=""
      HiddenTypes(137)=""
      HiddenTypes(138)=""
      HiddenTypes(139)=""
      HiddenTypes(140)=""
      HiddenTypes(141)=""
      HiddenTypes(142)=""
      HiddenTypes(143)=""
      HiddenTypes(144)=""
      HiddenTypes(145)=""
      HiddenTypes(146)=""
      HiddenTypes(147)=""
      HiddenTypes(148)=""
      HiddenTypes(149)=""
      HiddenTypes(150)=""
      HiddenTypes(151)=""
      HiddenTypes(152)=""
      HiddenTypes(153)=""
      HiddenTypes(154)=""
      HiddenTypes(155)=""
      HiddenTypes(156)=""
      HiddenTypes(157)=""
      HiddenTypes(158)=""
      HiddenTypes(159)=""
      HiddenTypes(160)=""
      HiddenTypes(161)=""
      HiddenTypes(162)=""
      HiddenTypes(163)=""
      HiddenTypes(164)=""
      HiddenTypes(165)=""
      HiddenTypes(166)=""
      HiddenTypes(167)=""
      HiddenTypes(168)=""
      HiddenTypes(169)=""
      HiddenTypes(170)=""
      HiddenTypes(171)=""
      HiddenTypes(172)=""
      HiddenTypes(173)=""
      HiddenTypes(174)=""
      HiddenTypes(175)=""
      HiddenTypes(176)=""
      HiddenTypes(177)=""
      HiddenTypes(178)=""
      HiddenTypes(179)=""
      HiddenTypes(180)=""
      HiddenTypes(181)=""
      HiddenTypes(182)=""
      HiddenTypes(183)=""
      HiddenTypes(184)=""
      HiddenTypes(185)=""
      HiddenTypes(186)=""
      HiddenTypes(187)=""
      HiddenTypes(188)=""
      HiddenTypes(189)=""
      HiddenTypes(190)=""
      HiddenTypes(191)=""
      HiddenTypes(192)=""
      HiddenTypes(193)=""
      HiddenTypes(194)=""
      HiddenTypes(195)=""
      HiddenTypes(196)=""
      HiddenTypes(197)=""
      HiddenTypes(198)=""
      HiddenTypes(199)=""
      HiddenTypes(200)=""
      HiddenTypes(201)=""
      HiddenTypes(202)=""
      HiddenTypes(203)=""
      HiddenTypes(204)=""
      HiddenTypes(205)=""
      HiddenTypes(206)=""
      HiddenTypes(207)=""
      HiddenTypes(208)=""
      HiddenTypes(209)=""
      HiddenTypes(210)=""
      HiddenTypes(211)=""
      HiddenTypes(212)=""
      HiddenTypes(213)=""
      HiddenTypes(214)=""
      HiddenTypes(215)=""
      HiddenTypes(216)=""
      HiddenTypes(217)=""
      HiddenTypes(218)=""
      HiddenTypes(219)=""
      HiddenTypes(220)=""
      HiddenTypes(221)=""
      HiddenTypes(222)=""
      HiddenTypes(223)=""
      HiddenTypes(224)=""
      HiddenTypes(225)=""
      HiddenTypes(226)=""
      HiddenTypes(227)=""
      HiddenTypes(228)=""
      HiddenTypes(229)=""
      HiddenTypes(230)=""
      HiddenTypes(231)=""
      HiddenTypes(232)=""
      HiddenTypes(233)=""
      HiddenTypes(234)=""
      HiddenTypes(235)=""
      HiddenTypes(236)=""
      HiddenTypes(237)=""
      HiddenTypes(238)=""
      HiddenTypes(239)=""
      HiddenTypes(240)=""
      HiddenTypes(241)=""
      HiddenTypes(242)=""
      HiddenTypes(243)=""
      HiddenTypes(244)=""
      HiddenTypes(245)=""
      HiddenTypes(246)=""
      HiddenTypes(247)=""
      HiddenTypes(248)=""
      HiddenTypes(249)=""
      HiddenTypes(250)=""
      HiddenTypes(251)=""
      HiddenTypes(252)=""
      HiddenTypes(253)=""
      HiddenTypes(254)=""
      HiddenTypes(255)=""
      FilterString=""
      FilterStringCaps=""
      bNoEmpty=False
      bNoFull=False
      bNoLocked=False
      ServerListClassName="UBrowser.UBrowserServerList"
      ServerListClass=None
      PingedList=None
      HiddenList=None
      UnpingedList=None
      Factories(0)=None
      Factories(1)=None
      Factories(2)=None
      Factories(3)=None
      Factories(4)=None
      Factories(5)=None
      Factories(6)=None
      Factories(7)=None
      Factories(8)=None
      Factories(9)=None
      QueryDone(0)=0
      QueryDone(1)=0
      QueryDone(2)=0
      QueryDone(3)=0
      QueryDone(4)=0
      QueryDone(5)=0
      QueryDone(6)=0
      QueryDone(7)=0
      QueryDone(8)=0
      QueryDone(9)=0
      Grid=None
      GridClass="UBrowser.UBrowserServerGrid"
      TimeElapsed=0.000000
      bPingSuspend=False
      bPingResume=False
      bPingResumeIntial=False
      bNoSort=False
      bSuspendPingOnClose=True
      SubsetList=None
      SupersetList=None
      RightClickMenuClass=Class'UBrowser.UBrowserRightClickMenu'
      bShowFailedServers=False
      bHadInitialRefresh=False
      FallbackFactory=0
      Filter=None
      Empty=None
      Full=None
      Locked=None
      HSplitter=None
      TypesGrid=None
      TypesList=None
      VSplitter=None
      InfoWindow=None
      InfoClient=None
      InfoItem=None
      InfoName="Info"
      WhiteColor=(R=255,G=255,B=255,A=0)
      PlayerCountLeader=""
      ServerCountLeader=""
      FilterText="Filter"
      FilterHelp="Filter servers by name, map, mutator, player name and so on."
      EmptyText="Empty"
      EmptyHelp="Show empty servers."
      FullText="Full"
      FullHelp="Show full servers."
      LockedText="Locked"
      LockedHelp="Show password-protected servers."
      PlayerCountName="Players"
      ServerCountName="Servers"
      QueryServerText="Querying master server (hit F5 if nothing happens)"
      QueryFailedText="Master Server Failed: "
      PingingText="Pinging Servers"
      CompleteText="Complete"
      ErrorString=""
      PingState=PS_QueryServer
}
