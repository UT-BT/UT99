class UBrowserFavoritesFact extends UBrowserServerListFactory;

var config int FavoriteCount;
var config string Favorites[100];

/* eg Favorites[0]=Host Name\10.0.0.1\7778\True */


function string ParseOption(string Input, int Pos)
{
	local int i;

	while(True)
	{
		if(Pos == 0)
		{
			i = InStr(Input, "\\");
			if(i != -1)
				Input = Left(Input, i);
			return Input;
		}

		i = InStr(Input, "\\");
		if(i == -1)
			return "";

		Input = Mid(Input, i+1);
		Pos--;
	}
}

function Query(optional bool bBySuperset, optional bool bInitial)
{
	local int i;
	local UBrowserServerList L;

	Super.Query(bBySuperset, bInitial);

	for(i=0;i<FavoriteCount;i++)
	{
		L = FoundServer(ParseOption(Favorites[i], 1), Int(ParseOption(Favorites[i], 2)), "", "Unreal", ParseOption(Favorites[i], 0));
		L.bKeepDescription = ParseOption(Favorites[i], 3) ~= (string(True));
	}

	QueryFinished(True);
}

function SaveFavorites()
{
	local UBrowserServerList I;

	FavoriteCount = 0;
	for(I = UBrowserServerList(PingedList.Next); i!=None; I = UBrowserServerList(I.Next))
	{
		if(FavoriteCount == 100)
			break;
		Favorites[FavoriteCount] = I.HostName$"\\"$I.IP$"\\"$string(I.QueryPort)$"\\"$string(I.bKeepDescription);

		FavoriteCount++;
	}

	for(I = UBrowserServerList(UnPingedList.Next); i!=None; I = UBrowserServerList(I.Next))
	{
		if(FavoriteCount == 100)
			break;
		Favorites[FavoriteCount] = I.HostName$"\\"$I.IP$"\\"$string(I.QueryPort)$"\\"$string(I.bKeepDescription);

		FavoriteCount++;
	}

	if(FavoriteCount < 100)
		Favorites[FavoriteCount] = "";

	SaveConfig();
}

defaultproperties
{
      FavoriteCount=23
      Favorites(0)="*Private BT Training SERVER | By KnoW\\95.211.109.182\\10201\\False"
      Favorites(1)="*Public BT Training SERVER X | By KnoW\\95.168.184.121\\1041\\False"
      Favorites(2)="*Public BT Training SERVER | By KnoW\\95.211.109.182\\1041\\False"
      Favorites(3)="*Public BT v469b Test SERVER | By KnoW\\95.211.109.182\\12901\\False"
      Favorites(4)="- EU - Bunny Track server\\173.199.111.57\\7778\\False"
      Favorites(5)="Barbies Monsterhunt World\\81.169.240.101\\7778\\False"
      Favorites(6)="Bunnytrack PUG server test 123\\192.168.178.99\\7778\\False"
      Favorites(7)="BunnyTrack.net Official Server 1 of 2 | Great BT for everyone\\176.58.120.227\\7778\\False"
      Favorites(8)="BunnyTrack.net Official Server 2 of 2 | Great BT for everyone\\176.58.120.227\\8889\\False"
      Favorites(9)="BunnyTrack.net Official Server USA | Great BT for everyone\\50.116.23.187\\7778\\False"
      Favorites(10)="[https://discord.gg/bunnytrack] Ranked BT Practice [Season 2]\\194.37.81.153\\8889\\False"
      Favorites(11)="[https://discord.gg/bunnytrack] Ranked BT Practice [Season 2]\\194.37.80.130\\7778\\False"
      Favorites(12)="[https://discord.gg/bunnytrack] Ranked BT Practice [Season 2]\\194.37.81.153\\7778\\False"
      Favorites(13)="[https://discord.gg/bunnytrack] Ranked BT Practice [Season 2]\\194.37.80.130\\8889\\False"
      Favorites(14)="[i4Games.eu] BT1 - BunnyTrack\\176.9.105.6\\17778\\False"
      Favorites(15)="[i4Games.eu] BT2 - BunnyTrack Training and Team Play\\176.9.105.6\\27778\\False"
      Favorites(16)="[i4Games.eu] BT3 - BunnyTrack Rush\\176.9.105.6\\37778\\False"
      Favorites(17)="[i4Games.eu] BT4 - BunnyTrack Premium Rush\\176.9.105.6\\47778\\False"
      Favorites(18)="87.101.4.56\\87.101.4.56\\7778\\False"
      Favorites(19)="Discrim BunnyTrack Ranked Practice\\37.187.115.22\\7778\\False"
      Favorites(20)="[https://discord.gg/bunnytrack] Ranked BT Practice [Season 2]\\194.37.80.130\\10000\\False"
      Favorites(21)="[https://discord.gg/bunnytrack] Ranked BT Practice [Season 2]\\194.37.80.130\\6667\\False"
      Favorites(22)="Discrim BunnyTrack Ranked Practice #2\\37.187.115.22\\8889\\False"
      Favorites(23)=""
      Favorites(24)=""
      Favorites(25)=""
      Favorites(26)=""
      Favorites(27)=""
      Favorites(28)=""
      Favorites(29)=""
      Favorites(30)=""
      Favorites(31)=""
      Favorites(32)=""
      Favorites(33)=""
      Favorites(34)=""
      Favorites(35)=""
      Favorites(36)=""
      Favorites(37)=""
      Favorites(38)=""
      Favorites(39)=""
      Favorites(40)=""
      Favorites(41)=""
      Favorites(42)=""
      Favorites(43)=""
      Favorites(44)=""
      Favorites(45)=""
      Favorites(46)=""
      Favorites(47)=""
      Favorites(48)=""
      Favorites(49)=""
      Favorites(50)=""
      Favorites(51)=""
      Favorites(52)=""
      Favorites(53)=""
      Favorites(54)=""
      Favorites(55)=""
      Favorites(56)=""
      Favorites(57)=""
      Favorites(58)=""
      Favorites(59)=""
      Favorites(60)=""
      Favorites(61)=""
      Favorites(62)=""
      Favorites(63)=""
      Favorites(64)=""
      Favorites(65)=""
      Favorites(66)=""
      Favorites(67)=""
      Favorites(68)=""
      Favorites(69)=""
      Favorites(70)=""
      Favorites(71)=""
      Favorites(72)=""
      Favorites(73)=""
      Favorites(74)=""
      Favorites(75)=""
      Favorites(76)=""
      Favorites(77)=""
      Favorites(78)=""
      Favorites(79)=""
      Favorites(80)=""
      Favorites(81)=""
      Favorites(82)=""
      Favorites(83)=""
      Favorites(84)=""
      Favorites(85)=""
      Favorites(86)=""
      Favorites(87)=""
      Favorites(88)=""
      Favorites(89)=""
      Favorites(90)=""
      Favorites(91)=""
      Favorites(92)=""
      Favorites(93)=""
      Favorites(94)=""
      Favorites(95)=""
      Favorites(96)=""
      Favorites(97)=""
      Favorites(98)=""
      Favorites(99)=""
}
