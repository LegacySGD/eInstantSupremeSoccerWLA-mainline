<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl"/>

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />
			
			<!--
			TEMPLATE
			Match:
			-->
			<x:template match="/">
				<x:apply-templates select="*"/>
				<x:apply-templates select="/output/root[position()=last()]" mode="last"/>
				<br/>
			</x:template>
			<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
				<lxslt:script lang="javascript">
					<![CDATA[
function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var result = parseScenario(scenario);
	var lineArr = result.line;

	var tranMap = parseTranslations(translations);
	var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);

	var r = [];
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<th class="tablehead" width="100%" colspan="5">');
	r.push(tranMap["baseTitle"]);
	r.push('</th>');
	r.push('</tr>');
	var winResult, symbolIdx;
	for (var idx = 0; idx < lineArr.length; idx++) {
		winResult = tranMap["winNo"];
		if (lineArr[idx].symbolWin) {
			winResult = tranMap["winYes"];
		}

		r.push('<tr>');
		r.push('<td class="tablebody" width="10%" rowspan="4">');
		r.push(tranMap["rowLabel"] + " " + lineArr[idx].idx);
		r.push('</td>');
		r.push('</tr>');

		r.push('<tr>');
		r.push('<td class="tablebody" width="30%">');
		r.push(tranMap["prizeValue"]);
		r.push('</td>');
		for (symbolIdx = 0; symbolIdx < 3; symbolIdx++) {
			r.push('<td class="tablebody" width="20%">');
			r.push(prizeMap[lineArr[idx].symbol.charAt(symbolIdx)]);
			r.push('</td>');
		}
		r.push('</tr>');

		r.push('<tr>');
		r.push('<td class="tablebody" width="30%">');
		r.push(tranMap["bonusSymbol"]);
		r.push('</td>');
		for (symbolIdx = 0; symbolIdx < 3; symbolIdx++) {
			r.push('<td class="tablebody" width="20%">');
			r.push(lineArr[idx].soccerSymbol.split(",")[symbolIdx]);
			r.push('</td>');
		}
		r.push('</tr>');

		r.push('<tr>');
		r.push('<td class="tablebody" width="30%">');
		r.push(tranMap["winLabel"]);
		r.push('</td>');
		r.push('<td class="tablebody" width="60%" colspan="3">');
		r.push(winResult);
		r.push('</td>');
		r.push('</tr>');

		if (idx < lineArr.length - 1) {
			r.push('<tr><td class="tablehead" width="100%" colspan="5"></td></tr>');
		}
	}
	r.push('</table>');

	winResult = '-';
	if (result.bonusWin) {
		winResult = prizeMap[result.bonusLevel];
	}
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<th class="tablehead" width="100%" colspan="5">');
	r.push(tranMap["bonusTitle"]);
	r.push('</th>');
	r.push('</tr>');
	r.push('<tr>');
	r.push('<td class="tablebody" colspan="2">');
	r.push(tranMap["bonusResult"]);
	r.push('</td>');
	r.push('<td class="tablebody" colspan="3">');
	if (result.bonusWin) {
		r.push(result.bonusResult);
	} else {
		r.push(tranMap["noBonus"]);
	}
	r.push('</td>');
	r.push('</tr>');
	r.push('<tr>');
	r.push('<td class="tablebody" colspan="2">');
	r.push(tranMap["bonusWin"]);
	r.push('</td>');
	r.push('<td class="tablebody" colspan="3">');
	r.push(winResult);
	r.push('</td>');
	r.push('</tr>');
	r.push('</table>');
	return r.join('');
}
function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function parsePrizes(prizeNamesDesc, prizeValues) {
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	var map = [];
	for (var idx = 0; idx < prizeNames.length; idx++) {
		map[prizeNames[idx]] = convertedPrizeValues[idx];
	}
	return map;
}
function parseTranslations(translationNodeSet) {
	var map = [];
	var list = translationNodeSet.item(0).getChildNodes();
	for (var idx = 1; idx < list.getLength(); idx++) {
		var childNode = list.item(idx);
		if (childNode.name == "phrase") {
			map[childNode.getAttribute("key")] = childNode.getAttribute("value");
		}
	}
	return map;
}

/*
 * Result sample.
 * 
 * Prize Division 18 - G+H+J+5
 * H0,H0,H1:G0,G0,G0:J1,J0,J0:I0,A1,F0|OXXX...
 * {
 *		bonusWin: true,
 *		bonusLevel: 5,
 *		line: [
 *			{idx: 1, symbol:"HHH", symbolWin: true,  soccerSymbol: " ,X, "},
 *			{idx: 2, symbol:"GGG", symbolWin: true,  soccerSymbol: " , , "},
 *			{idx: 3, symbol:"JJJ", symbolWin: true,  soccerSymbol: " ,X, "},
 *			{idx: 4, symbol:"IAF", symbolWin: false, soccerSymbol: " ,X, "}
 *		]
 * }
 */
function parseScenario(scenario) {

	function parseBonusSymbol(ls) {
		if (ls == 1) {
			return "X";
		} else if (ls == 2) {
			return "XX";
		} else {
			return " ";
		}
	}

	var symbolData = scenario.split("|")[0];
	var bonusSymbol = scenario.split("|")[1];
	var lineArr = symbolData.split(":");
	var idx, line, symbolArr, bonusTrigger = 0, detail, detailResult = [];
	for (idx = 0; idx < lineArr.length; idx++) {
		line = lineArr[idx];
		symbolArr = line.split(",");
		var lineSymbol = symbolArr[0].charAt(0) + symbolArr[1].charAt(0) + symbolArr[2].charAt(0);
		var symbolWin = false;
		if (symbolArr[0].charAt(0) === symbolArr[1].charAt(0) && symbolArr[1].charAt(0) === symbolArr[2].charAt(0)) {
			symbolWin = true;
		}
		var lineSoccer = parseInt(symbolArr[0].charAt(1)) + parseInt(symbolArr[1].charAt(1)) + parseInt(symbolArr[2].charAt(1));
		var soccerSymbol = parseBonusSymbol(parseInt(symbolArr[0].charAt(1))) + "," + parseBonusSymbol(parseInt(symbolArr[1].charAt(1))) + "," + parseBonusSymbol(parseInt(symbolArr[2].charAt(1)));
		bonusTrigger += lineSoccer;
		detail = {idx: (idx + 1), symbol: lineSymbol, symbolWin: symbolWin, soccerSymbol: soccerSymbol};
		detailResult.push(detail);
	}
	var bonusWin = false;
	var soccerSum = 0, bonusLevel = "", ticket = "";
	if (bonusTrigger === 3) {
		bonusWin = true;
		for (idx = 0; idx < bonusSymbol.length; idx++) {
			if ("O" === bonusSymbol.charAt(idx)) {
				soccerSum++;
			}
		}
	}
	switch (soccerSum) {
		case 1:
			bonusLevel = "M5";
			ticket = "IW5";
			break;
		case 2:
			bonusLevel = "M4";
			ticket = "IW4";
			break;
		case 3:
			bonusLevel = "M3";
			ticket = "IW3";
			break;
		case 4:
			bonusLevel = "M2";
			ticket = "IW2";
			break;
		case 5:
			bonusLevel = "M1";
			ticket = "IW1";
			break;
		default:
			bonusLevel = "-";
			ticket = "-";
	}
	var result = {line: detailResult, bonusLevel: bonusLevel, bonusWin: bonusWin, bonusResult: bonusSymbol, ticket: ticket};
	return result;
}
					]]>
				</lxslt:script>
			</lxslt:component>
			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>
		
			<!--
			TEMPLATE
			Match:		digested/game
			-->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="History.Detail" />
				</x:if>
				<x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
					<x:call-template name="History.Detail" />
				</x:if>
			</x:template>
		
			<!--
			TEMPLATE
			Name:		Wager.Detail (base game)
			-->
			<x:template name="History.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value"/>
							<x:value-of select="': '"/>
							<x:value-of select="OutcomeDetail/RngTxnId"/>
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>
		
			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			
			<x:template match="text()"/>
			
		</x:stylesheet>
	</xsl:template>
	
	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
		    <clickcount>
		        <x:value-of select="."/>
		    </clickcount>
		</x:template>
		<x:template match="*|@*|text()">
		    <x:apply-templates/>
		</x:template>
	</xsl:template>
	
</xsl:stylesheet>
