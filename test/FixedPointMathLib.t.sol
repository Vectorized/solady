// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract FixedPointMathLibTest is SoladyTest {
    function testExpWad() public {
        assertEq(FixedPointMathLib.expWad(-42139678854452767551), 0);

        assertEq(FixedPointMathLib.expWad(-3e18), 49787068367863942);
        assertEq(FixedPointMathLib.expWad(-2e18), 135335283236612691);
        assertEq(FixedPointMathLib.expWad(-1e18), 367879441171442321);

        assertEq(FixedPointMathLib.expWad(-0.5e18), 606530659712633423);
        assertEq(FixedPointMathLib.expWad(-0.3e18), 740818220681717866);

        assertEq(FixedPointMathLib.expWad(0), 1000000000000000000);

        assertEq(FixedPointMathLib.expWad(0.3e18), 1349858807576003103);
        assertEq(FixedPointMathLib.expWad(0.5e18), 1648721270700128146);

        assertEq(FixedPointMathLib.expWad(1e18), 2718281828459045235);
        assertEq(FixedPointMathLib.expWad(2e18), 7389056098930650227);
        assertEq(FixedPointMathLib.expWad(3e18), 20085536923187667741);
        // True value: 20085536923187667740.92

        assertEq(FixedPointMathLib.expWad(10e18), 220264657948067165169_80);
        // True value: 22026465794806716516957.90
        // Relative error 9.987984547746668e-22

        assertEq(FixedPointMathLib.expWad(50e18), 5184705528587072464_148529318587763226117);
        // True value: 5184705528587072464_087453322933485384827.47
        // Relative error: 1.1780031733243328e-20

        assertEq(
            FixedPointMathLib.expWad(100e18),
            268811714181613544841_34666106240937146178367581647816351662017
        );
        // True value: 268811714181613544841_26255515800135873611118773741922415191608
        // Relative error: 3.128803544297531e-22

        assertEq(
            FixedPointMathLib.expWad(135305999368893231588),
            578960446186580976_50144101621524338577433870140581303254786265309376407432913
        );
        // True value: 578960446186580976_49816762928942336782129491980154662247847962410455084893091
        // Relative error: 5.653904247484822e-21
    }

    // Notes on lambertW0Wad:
    //
    // If you want to attempt finding a better approximation, look at
    // https://github.com/recmo/experiment-solexp/blob/main/approximate_mpmath.ipynb
    // I somehow can't get it to reproduce the approximation constants for `lnWad`.
    // Let me know if you can get the code to reproduce the approximation constants for `lnWad`.

    event TestingLambertW0WadMonotonicallyIncreasing(
        int256 a, int256 b, int256 w0a, int256 w0b, bool success, uint256 gasUsed
    );

    int256 internal constant _ONE_DIV_EXP = 367879441171442321;
    int256 internal constant _LAMBERT_W0_MIN = -367879441171442321;
    int256 internal constant _EXP = 2718281828459045235;
    int256 internal constant _WAD = 10 ** 18;

    function testLambertW0WadKnownValues() public {
        _checkLambertW0Wad(0, 0);
        _checkLambertW0Wad(1, 1);
        _checkLambertW0Wad(2, 2);
        _checkLambertW0Wad(3, 2);
        _checkLambertW0Wad(131071, 131070);
        _checkLambertW0Wad(17179869183, 17179868887);
        _checkLambertW0Wad(1000000000000000000, 567143290409783872);
        _checkLambertW0Wad(-3678794411715, -3678807945318);
        _checkLambertW0Wad(_LAMBERT_W0_MIN, -999999999741585709);
        // These are exact values.
        _checkLambertW0Wad(2 ** 255 - 1, 130435123404408416612);
        _checkLambertW0Wad(2 ** 254 - 1, 129747263755102316133);
        _checkLambertW0Wad(2 ** 253 - 1, 129059431996357330139);
        _checkLambertW0Wad(2 ** 252 - 1, 128371628422812486425);
        _checkLambertW0Wad(2 ** 251 - 1, 127683853333788079721);
        _checkLambertW0Wad(2 ** 250 - 1, 126996107033385166927);
        _checkLambertW0Wad(2 ** 249 - 1, 126308389830587715420);
        _checkLambertW0Wad(2 ** 248 - 1, 125620702039367489656);
        _checkLambertW0Wad(2 ** 247 - 1, 124933043978791764502);
        _checkLambertW0Wad(2 ** 246 - 1, 124245415973133957088);
        _checkLambertW0Wad(2 ** 245 - 1, 123557818351987272451);
        _checkLambertW0Wad(2 ** 244 - 1, 122870251450381461880);
        _checkLambertW0Wad(2 ** 243 - 1, 122182715608902796703);
        _checkLambertW0Wad(2 ** 242 - 1, 121495211173817364188);
        _checkLambertW0Wad(2 ** 241 - 1, 120807738497197796422);
        _checkLambertW0Wad(2 ** 240 - 1, 120120297937053547320);
        _checkLambertW0Wad(2 ** 239 - 1, 119432889857464837488);
        _checkLambertW0Wad(2 ** 238 - 1, 118745514628720391363);
        _checkLambertW0Wad(2 ** 237 - 1, 118058172627459096009);
        _checkLambertW0Wad(2 ** 236 - 1, 117370864236815716134);
        _checkLambertW0Wad(2 ** 235 - 1, 116683589846570805279);
        _checkLambertW0Wad(2 ** 234 - 1, 115996349853304958814);
        _checkLambertW0Wad(2 ** 233 - 1, 115309144660557560280);
        _checkLambertW0Wad(2 ** 232 - 1, 114621974678990178815);
        _checkLambertW0Wad(2 ** 231 - 1, 113934840326554781918);
        _checkLambertW0Wad(2 ** 230 - 1, 113247742028666934564);
        _checkLambertW0Wad(2 ** 229 - 1, 112560680218384162820);
        _checkLambertW0Wad(2 ** 228 - 1, 111873655336589667598);
        _checkLambertW0Wad(2 ** 227 - 1, 111186667832181581935);
        _checkLambertW0Wad(2 ** 226 - 1, 110499718162267973459);
        _checkLambertW0Wad(2 ** 225 - 1, 109812806792367802251);
        _checkLambertW0Wad(2 ** 224 - 1, 109125934196618053331);
        _checkLambertW0Wad(2 ** 223 - 1, 108439100857987272488);
        _checkLambertW0Wad(2 ** 222 - 1, 107752307268495744067);
        _checkLambertW0Wad(2 ** 221 - 1, 107065553929442559763);
        _checkLambertW0Wad(2 ** 220 - 1, 106378841351639838444);
        _checkLambertW0Wad(2 ** 219 - 1, 105692170055654368478);
        _checkLambertW0Wad(2 ** 218 - 1, 105005540572056956171);
        _checkLambertW0Wad(2 ** 217 - 1, 104318953441679776592);
        _checkLambertW0Wad(2 ** 216 - 1, 103632409215882036434);
        _checkLambertW0Wad(2 ** 215 - 1, 102945908456824272609);
        _checkLambertW0Wad(2 ** 214 - 1, 102259451737751625038);
        _checkLambertW0Wad(2 ** 213 - 1, 101573039643286437675);
        _checkLambertW0Wad(2 ** 212 - 1, 100886672769730558166);
        _checkLambertW0Wad(2 ** 211 - 1, 100200351725377723788);
        _checkLambertW0Wad(2 ** 210 - 1, 99514077130836439501);
        _checkLambertW0Wad(2 ** 209 - 1, 98827849619363773067);
        _checkLambertW0Wad(2 ** 208 - 1, 98141669837210512407);
        _checkLambertW0Wad(2 ** 207 - 1, 97455538443978151616);
        _checkLambertW0Wad(2 ** 206 - 1, 96769456112988194563);
        _checkLambertW0Wad(2 ** 205 - 1, 96083423531664288650);
        _checkLambertW0Wad(2 ** 204 - 1, 95397441401927726359);
        _checkLambertW0Wad(2 ** 203 - 1, 94711510440606878644);
        _checkLambertW0Wad(2 ** 202 - 1, 94025631379861152095);
        _checkLambertW0Wad(2 ** 201 - 1, 93339804967620091367);
        _checkLambertW0Wad(2 ** 200 - 1, 92654031968038279517);
        _checkLambertW0Wad(2 ** 199 - 1, 91968313161966721893);
        _checkLambertW0Wad(2 ** 198 - 1, 91282649347441434152);
        _checkLambertW0Wad(2 ** 197 - 1, 90597041340189991908);
        _checkLambertW0Wad(2 ** 196 - 1, 89911489974156838659);
        _checkLambertW0Wad(2 ** 195 - 1, 89225996102048190100);
        _checkLambertW0Wad(2 ** 194 - 1, 88540560595897416858);
        _checkLambertW0Wad(2 ** 193 - 1, 87855184347651834275);
        _checkLambertW0Wad(2 ** 192 - 1, 87169868269781877263);
        _checkLambertW0Wad(2 ** 191 - 1, 86484613295913690725);
        _checkLambertW0Wad(2 ** 190 - 1, 85799420381486221653);
        _checkLambertW0Wad(2 ** 189 - 1, 85114290504433958190);
        _checkLambertW0Wad(2 ** 188 - 1, 84429224665896523735);
        _checkLambertW0Wad(2 ** 187 - 1, 83744223890956400983);
        _checkLambertW0Wad(2 ** 186 - 1, 83059289229406131801);
        _checkLambertW0Wad(2 ** 185 - 1, 82374421756546414467);
        _checkLambertW0Wad(2 ** 184 - 1, 81689622574016600237);
        _checkLambertW0Wad(2 ** 183 - 1, 81004892810659176931);
        _checkLambertW0Wad(2 ** 182 - 1, 80320233623419918558);
        _checkLambertW0Wad(2 ** 181 - 1, 79635646198285477393);
        _checkLambertW0Wad(2 ** 180 - 1, 78951131751260298782);
        _checkLambertW0Wad(2 ** 179 - 1, 78266691529384849812);
        _checkLambertW0Wad(2 ** 178 - 1, 77582326811797271395);
        _checkLambertW0Wad(2 ** 177 - 1, 76898038910840689756);
        _checkLambertW0Wad(2 ** 176 - 1, 76213829173218558571);
        _checkLambertW0Wad(2 ** 175 - 1, 75529698981200547567);
        _checkLambertW0Wad(2 ** 174 - 1, 74845649753881648207);
        _checkLambertW0Wad(2 ** 173 - 1, 74161682948497332759);
        _checkLambertW0Wad(2 ** 172 - 1, 73477800061797780656);
        _checkLambertW0Wad(2 ** 171 - 1, 72794002631484376331);
        _checkLambertW0Wad(2 ** 170 - 1, 72110292237711886966);
        _checkLambertW0Wad(2 ** 169 - 1, 71426670504659947705);
        _checkLambertW0Wad(2 ** 168 - 1, 70743139102177717275);
        _checkLambertW0Wad(2 ** 167 - 1, 70059699747505819935);
        _checkLambertW0Wad(2 ** 166 - 1, 69376354207079961679);
        _checkLambertW0Wad(2 ** 165 - 1, 68693104298420901379);
        _checkLambertW0Wad(2 ** 164 - 1, 68009951892115772747);
        _checkLambertW0Wad(2 ** 163 - 1, 67326898913896092682);
        _checkLambertW0Wad(2 ** 162 - 1, 66643947346818157796);
        _checkLambertW0Wad(2 ** 161 - 1, 65961099233551926143);
        _checkLambertW0Wad(2 ** 160 - 1, 65278356678784907905);
        _checkLambertW0Wad(2 ** 159 - 1, 64595721851748049983);
        _checkLambertW0Wad(2 ** 158 - 1, 63913196988871098107);
        _checkLambertW0Wad(2 ** 157 - 1, 63230784396575459844);
        _checkLambertW0Wad(2 ** 156 - 1, 62548486454213176429);
        _checkLambertW0Wad(2 ** 155 - 1, 61866305617161244980);
        _checkLambertW0Wad(2 ** 154 - 1, 61184244420081220067);
        _checkLambertW0Wad(2 ** 153 - 1, 60502305480354769865);
        _checkLambertW0Wad(2 ** 152 - 1, 59820491501706673077);
        _checkLambertW0Wad(2 ** 151 - 1, 59138805278027624755);
        _checkLambertW0Wad(2 ** 150 - 1, 58457249697410179101);
        _checkLambertW0Wad(2 ** 149 - 1, 57775827746412203235);
        _checkLambertW0Wad(2 ** 148 - 1, 57094542514563356374);
        _checkLambertW0Wad(2 ** 147 - 1, 56413397199131353678);
        _checkLambertW0Wad(2 ** 146 - 1, 55732395110166133991);
        _checkLambertW0Wad(2 ** 145 - 1, 55051539675841537897);
        _checkLambertW0Wad(2 ** 144 - 1, 54370834448115730535);
        _checkLambertW0Wad(2 ** 143 - 1, 53690283108733387465);
        _checkLambertW0Wad(2 ** 142 - 1, 53009889475594618649);
        _checkLambertW0Wad(2 ** 141 - 1, 52329657509517754228);
        _checkLambertW0Wad(2 ** 140 - 1, 51649591321425477661);
        _checkLambertW0Wad(2 ** 139 - 1, 50969695179986390948);
        _checkLambertW0Wad(2 ** 138 - 1, 50289973519746960243);
        _checkLambertW0Wad(2 ** 137 - 1, 49610430949791948630);
        _checkLambertW0Wad(2 ** 136 - 1, 48931072262974930811);
        _checkLambertW0Wad(2 ** 135 - 1, 48251902445764340905);
        _checkLambertW0Wad(2 ** 134 - 1, 47572926688754773801);
        _checkLambertW0Wad(2 ** 133 - 1, 46894150397897992742);
        _checkLambertW0Wad(2 ** 132 - 1, 46215579206513348095);
        _checkLambertW0Wad(2 ** 131 - 1, 45537218988143149666);
        _checkLambertW0Wad(2 ** 130 - 1, 44859075870325031417);
        _checkLambertW0Wad(2 ** 129 - 1, 44181156249360587882);
        _checkLambertW0Wad(2 ** 128 - 1, 43503466806167642613);
        _checkLambertW0Wad(2 ** 127 - 1, 42826014523312541917);
        _checkLambertW0Wad(2 ** 126 - 1, 42148806703328979292);
        _checkLambertW0Wad(2 ** 125 - 1, 41471850988441194251);
        _checkLambertW0Wad(2 ** 124 - 1, 40795155381822122767);
        _checkLambertW0Wad(2 ** 123 - 1, 40118728270531400808);
        _checkLambertW0Wad(2 ** 122 - 1, 39442578450294263667);
        _checkLambertW0Wad(2 ** 121 - 1, 38766715152300604375);
        _checkLambertW0Wad(2 ** 120 - 1, 38091148072224059569);
        _checkLambertW0Wad(2 ** 119 - 1, 37415887401684336100);
        _checkLambertW0Wad(2 ** 118 - 1, 36740943862402491609);
        _checkLambertW0Wad(2 ** 117 - 1, 36066328743329022902);
        _checkLambertW0Wad(2 ** 116 - 1, 35392053941058967434);
        _checkLambertW0Wad(2 ** 115 - 1, 34718132003887455986);
        _checkLambertW0Wad(2 ** 114 - 1, 34044576179904059477);
        _checkLambertW0Wad(2 ** 113 - 1, 33371400469575784902);
        _checkLambertW0Wad(2 ** 112 - 1, 32698619683327803297);
        _checkLambertW0Wad(2 ** 111 - 1, 32026249504699254799);
        _checkLambertW0Wad(2 ** 110 - 1, 31354306559730344521);
        _checkLambertW0Wad(2 ** 109 - 1, 30682808493328298780);
        _checkLambertW0Wad(2 ** 108 - 1, 30011774053465850808);
        _checkLambertW0Wad(2 ** 107 - 1, 29341223184189485097);
        _checkLambertW0Wad(2 ** 106 - 1, 28671177128558970924);
        _checkLambertW0Wad(2 ** 105 - 1, 28001658542808735364);
        _checkLambertW0Wad(2 ** 104 - 1, 27332691623220201135);
        _checkLambertW0Wad(2 ** 103 - 1, 26664302247428250682);
        _checkLambertW0Wad(2 ** 102 - 1, 25996518132161712657);
        _checkLambertW0Wad(2 ** 101 - 1, 25329369009746106264);
        _checkLambertW0Wad(2 ** 100 - 1, 24662886826087826761);
        _checkLambertW0Wad(2 ** 99 - 1, 23997105963326166352);
        _checkLambertW0Wad(2 ** 98 - 1, 23332063490900058530);
        _checkLambertW0Wad(2 ** 97 - 1, 22667799449451523321);
        _checkLambertW0Wad(2 ** 96 - 1, 22004357172804292983);
        _checkLambertW0Wad(2 ** 95 - 1, 21341783654247925671);
        _checkLambertW0Wad(2 ** 94 - 1, 20680129964567978803);
        _checkLambertW0Wad(2 ** 93 - 1, 20019451730746615034);
        _checkLambertW0Wad(2 ** 92 - 1, 19359809686086176343);
        _checkLambertW0Wad(2 ** 91 - 1, 18701270304772358157);
        _checkLambertW0Wad(2 ** 90 - 1, 18043906536712772323);
        _checkLambertW0Wad(2 ** 89 - 1, 17387798662016868795);
        _checkLambertW0Wad(2 ** 88 - 1, 16733035288929945451);
        _checkLambertW0Wad(2 ** 87 - 1, 16079714524670107222 + 1);
        _checkLambertW0Wad(2 ** 86 - 1, 15427945355807184379);
        _checkLambertW0Wad(2 ** 85 - 1, 14777849284057868231);
        _checkLambertW0Wad(2 ** 84 - 1, 14129562275318189632);
        _checkLambertW0Wad(2 ** 83 - 1, 13483237095324880705);
        _checkLambertW0Wad(2 ** 82 - 1, 12839046125789215063);
        _checkLambertW0Wad(2 ** 81 - 1, 12197184781931118579);
        _checkLambertW0Wad(2 ** 80 - 1, 11557875688514566228 - 1);
        _checkLambertW0Wad(2 ** 79 - 1, 10921373820226202580);
        _checkLambertW0Wad(2 ** 78 - 1, 10287972878516218499);
        _checkLambertW0Wad(2 ** 77 - 1, 9658013267990184319);
        _checkLambertW0Wad(2 ** 76 - 1, 9031892161491509531);
        _checkLambertW0Wad(2 ** 75 - 1, 8410076319328428686);
        _checkLambertW0Wad(2 ** 74 - 1, 7793118576966979948);
        _checkLambertW0Wad(2 ** 73 - 1, 7181679269695846234);
        _checkLambertW0Wad(2 ** 72 - 1, 6576554370186862926);
        _checkLambertW0Wad(2 ** 71 - 1, 5978712844468804878 - 1);
        _checkLambertW0Wad(2 ** 70 - 1, 5389346779005776683);
        _checkLambertW0Wad(2 ** 69 - 1, 4809939316762921936);
        _checkLambertW0Wad(2 ** 68 - 1, 4242357480017482271);
        _checkLambertW0Wad(2 ** 67 - 1, 3688979548845126287);
        _checkLambertW0Wad(2 ** 66 - 1, 3152869312105232629);
        _checkLambertW0Wad(2 ** 65 - 1, 2638010157689274059);
        _checkLambertW0Wad(2 ** 64 - 1, 2149604165721149566);
        _checkLambertW0Wad(2 ** 63 - 1, 1694407549795038335);
        _checkLambertW0Wad(2 ** 62 - 1, 1280973323147500590);
        _checkLambertW0Wad(2 ** 61 - 1, 919438481612859603);
        _checkLambertW0Wad(2 ** 60 - 1, 620128202996354327);
        _checkLambertW0Wad(2 ** 59 - 1, 390213425026895126);
        _checkLambertW0Wad(2 ** 58 - 1, 229193491169149614);
        _checkLambertW0Wad(2 ** 57 - 1, 126935310044982397);
        _checkLambertW0Wad(2 ** 56 - 1, 67363429834711483);
        _checkLambertW0Wad(2 ** 55 - 1, 34796675828817814);
        _checkLambertW0Wad(2 ** 54 - 1, 17698377658513340);
        _checkLambertW0Wad(2 ** 53 - 1, 8927148493627578);
        _checkLambertW0Wad(2 ** 52 - 1, 4483453146102402);
        _checkLambertW0Wad(2 ** 51 - 1, 2246746269994097);
        _checkLambertW0Wad(2 ** 50 - 1, 1124634392838166);
        _checkLambertW0Wad(2 ** 49 - 1, 562633308112667);
        _checkLambertW0Wad(2 ** 48 - 1, 281395781982528);
        _checkLambertW0Wad(2 ** 47 - 1, 140717685495042);
        _checkLambertW0Wad(2 ** 46 - 1, 70363792940114);
        _checkLambertW0Wad(2 ** 45 - 1, 35183134214121);
        _checkLambertW0Wad(2 ** 44 - 1, 17591876567571);
        _checkLambertW0Wad(2 ** 43 - 1, 8796015651975);
        _checkLambertW0Wad(2 ** 42 - 1, 4398027168417);
        _checkLambertW0Wad(2 ** 41 - 1, 2199018419863);
        _checkLambertW0Wad(2 ** 40 - 1, 1099510418851);
        _checkLambertW0Wad(2 ** 39 - 1, 549755511655);
        _checkLambertW0Wad(2 ** 38 - 1, 274877831385);
        _checkLambertW0Wad(2 ** 37 - 1, 137438934581);
        _checkLambertW0Wad(2 ** 36 - 1, 68719472012);
        _checkLambertW0Wad(2 ** 35 - 1, 34359737186);
        _checkLambertW0Wad(2 ** 34 - 1, 17179868887);
        _checkLambertW0Wad(2 ** 33 - 1, 8589934517);
        _checkLambertW0Wad(2 ** 32 - 1, 4294967276);
        _checkLambertW0Wad(2 ** 31 - 1, 2147483642);
        _checkLambertW0Wad(2 ** 30 - 1, 1073741821);
        _checkLambertW0Wad(2 ** 29 - 1, 536870910);
        _checkLambertW0Wad(2 ** 28 - 1, 268435454);
        _checkLambertW0Wad(2 ** 27 - 1, 134217726);
        _checkLambertW0Wad(2 ** 26 - 1, 67108862);
        _checkLambertW0Wad(2 ** 25 - 1, 33554430);
        _checkLambertW0Wad(2 ** 24 - 1, 16777214);
        _checkLambertW0Wad(2 ** 23 - 1, 8388606);
        _checkLambertW0Wad(2 ** 22 - 1, 4194302);
        _checkLambertW0Wad(2 ** 21 - 1, 2097150);
        _checkLambertW0Wad(2 ** 20 - 1, 1048574);
        _checkLambertW0Wad(2 ** 19 - 1, 524286);
        _checkLambertW0Wad(2 ** 18 - 1, 262142);
        _checkLambertW0Wad(2 ** 17 - 1, 131070);
        _checkLambertW0Wad(2 ** 16 - 1, 65534);
        _checkLambertW0Wad(2 ** 15 - 1, 32766);
        _checkLambertW0Wad(2 ** 14 - 1, 16382);
        _checkLambertW0Wad(2 ** 13 - 1, 8190);
        _checkLambertW0Wad(2 ** 12 - 1, 4094);
        _checkLambertW0Wad(2 ** 11 - 1, 2046);
        _checkLambertW0Wad(2 ** 10 - 1, 1022);
        _checkLambertW0Wad(2 ** 9 - 1, 510);
        _checkLambertW0Wad(2 ** 8 - 1, 254);
    }

    function testLambertW0WadRevertsForOutOfDomain() public {
        FixedPointMathLib.lambertW0Wad(_LAMBERT_W0_MIN);
        for (int256 i = 0; i <= 10; ++i) {
            vm.expectRevert(FixedPointMathLib.OutOfDomain.selector);
            FixedPointMathLib.lambertW0Wad(_LAMBERT_W0_MIN - 1 - i);
        }
        vm.expectRevert(FixedPointMathLib.OutOfDomain.selector);
        FixedPointMathLib.lambertW0Wad(-type(int256).max);
    }

    function _checkLambertW0Wad(int256 x, int256 expected) internal {
        unchecked {
            uint256 gasBefore = gasleft();
            int256 w = FixedPointMathLib.lambertW0Wad(x);
            uint256 gasUsed = gasBefore - gasleft();
            emit LogInt("x", x);
            emit LogUint("gasUsed", gasUsed);
            assertEq(w, expected);
        }
    }

    function testLambertW0WadAccuracy() public {
        testLambertW0WadAccuracy(uint184(int184(_testLamberW0WadAccuracyThres())));
        testLambertW0WadAccuracy(2 ** 184 - 1);
    }

    function testLambertW0WadAccuracy(uint184 a) public {
        int256 x = int256(int184(a));
        if (x >= _testLamberW0WadAccuracyThres()) {
            int256 l = FixedPointMathLib.lnWad(x);
            int256 r = x * l / _WAD;
            int256 w = FixedPointMathLib.lambertW0Wad(r);
            assertLt(FixedPointMathLib.abs(l - w), 0xff);
        }
    }

    function _testLamberW0WadAccuracyThres() internal pure returns (int256) {
        unchecked {
            return _ONE_DIV_EXP + _ONE_DIV_EXP * 0.01 ether / 1 ether;
        }
    }

    function testLambertW0WadWithinBounds(int256 x) public {
        if (x <= 0) x = _boundLambertW0WadInput(x);
        int256 w = FixedPointMathLib.lambertW0Wad(x);
        assertTrue(w <= x);
        unchecked {
            if (x > _EXP) {
                int256 l = FixedPointMathLib.lnWad(x);
                assertGt(l, 0);
                int256 ll = FixedPointMathLib.lnWad(l);
                int256 q = ll * _WAD;
                int256 lower = l - ll + q / (2 * l);
                if (x > _EXP + 4) {
                    assertLt(lower, w + 1);
                } else {
                    assertLt(lower, w + 2);
                }
                int256 upper = l - ll + (q * _EXP) / (l * (_EXP - _WAD)) + 1;
                assertLt(w, upper);
            }
        }
    }

    function testLambertW0WadWithinBounds() public {
        unchecked {
            for (int256 i = -10; i != 20; ++i) {
                testLambertW0WadWithinBounds(_EXP + i);
            }
            testLambertW0WadWithinBounds(type(int256).max);
        }
    }

    function testLambertW0WadMonotonicallyIncreasing() public {
        unchecked {
            for (uint256 i; i <= 256; ++i) {
                uint256 x = 1 << i;
                testLambertW0WadMonotonicallyIncreasingAround(int256(x));
                testLambertW0WadMonotonicallyIncreasingAround(int256(x - 1));
            }
            for (uint256 i; i <= 57; ++i) {
                uint256 x = 1 << i;
                testLambertW0WadMonotonicallyIncreasingAround(-int256(x));
                testLambertW0WadMonotonicallyIncreasingAround(-int256(x - 1));
            }
        }
    }

    function testLambertW0WadMonotonicallyIncreasing2() public {
        // These are some problematic values gathered over the attempts.
        // Some might not be problematic now.
        _testLambertW0WadMonoAround(0x598cdf77327d789dc);
        _testLambertW0WadMonoAround(0x3c8d97dfe4afb1b05);
        _testLambertW0WadMonoAround(0x56a147b480c03cc22);
        _testLambertW0WadMonoAround(0x3136f439c231d0bb9);
        _testLambertW0WadMonoAround(0x2ae7cff17ef2469a1);
        _testLambertW0WadMonoAround(0x1de668fd7afcf61cc);
        _testLambertW0WadMonoAround(0x15024b2a35f2cdd95);
        _testLambertW0WadMonoAround(0x11a65ae94b59590f9);
        _testLambertW0WadMonoAround(0xf0c2c82174dffb7e);
        _testLambertW0WadMonoAround(0xed3e56938cb11626);
        _testLambertW0WadMonoAround(0xecf5c4e511142439);
        _testLambertW0WadMonoAround(0xc0755fa2b4033cb0);
        _testLambertW0WadMonoAround(0xa235db282ea4edc6);
        _testLambertW0WadMonoAround(0x9ff2ec5c26eec112);
        _testLambertW0WadMonoAround(0xa0c3c4e36f4415f1);
        _testLambertW0WadMonoAround(0x9b9f0e8d61287782);
        _testLambertW0WadMonoAround(0x7df719d1a4a7b8ad);
        _testLambertW0WadMonoAround(0x7c881679a1464d25);
        _testLambertW0WadMonoAround(0x7bec47487071495a);
        _testLambertW0WadMonoAround(0x7be31c75fc717f9f);
        _testLambertW0WadMonoAround(0x7bbb4e0716eeca53);
        _testLambertW0WadMonoAround(0x78e59d40a92b443b);
        _testLambertW0WadMonoAround(0x77658c4ad3af717d);
        _testLambertW0WadMonoAround(0x75ae9afa425919fe);
        _testLambertW0WadMonoAround(0x7526092d05bef41f);
        _testLambertW0WadMonoAround(0x52896fe82be03dfe);
        _testLambertW0WadMonoAround(0x4f05b0ddf3b71a19);
        _testLambertW0WadMonoAround(0x3094b0feb93943fd);
        _testLambertW0WadMonoAround(0x2ef215ae6701c40e);
        _testLambertW0WadMonoAround(0x2ebd1c82095d6a92);
        _testLambertW0WadMonoAround(0x2e520a4e670d52bb);
        _testLambertW0WadMonoAround(0xfc2f004412e5ce69);
        _testLambertW0WadMonoAround(0x158bc0b201103a7fc);
        _testLambertW0WadMonoAround(0x39280df60945c436b);
        _testLambertW0WadMonoAround(0x47256e5d374b35f74);
        _testLambertW0WadMonoAround(0x2b9568ffb08c155a4);
        _testLambertW0WadMonoAround(0x1b60b07806956f34d);
        _testLambertW0WadMonoAround(0x21902755d1eee824c);
        _testLambertW0WadMonoAround(0x6e15c8a6ee6e4fca4);
        _testLambertW0WadMonoAround(0x5b13067d92d8e49c6);
        _testLambertW0WadMonoAround(0x2826ebc1fce90cf6e);
        _testLambertW0WadMonoAround(0x215eb5aa1041510a4);
        _testLambertW0WadMonoAround(0x47b20347b57504c32);
        _testLambertW0WadMonoAround(0x75e8fd53f8c90f95a);
        _testLambertW0WadMonoAround(0x43e8d80f9af282627);
        _testLambertW0WadMonoAround(0x3cf555b5fd4f20615);
        _testLambertW0WadMonoAround(0xaff4b8b52f8355e6e);
        _testLambertW0WadMonoAround(0x529e89e77ae046255);
        _testLambertW0WadMonoAround(0x1f0289433f07cbf53b);
        _testLambertW0WadMonoAround(0xc1f6e56c2001d9432);
        _testLambertW0WadMonoAround(0x5e4117305c6e33ebc);
        _testLambertW0WadMonoAround(0x2b416472dce2ea26d);
        _testLambertW0WadMonoAround(0x71f55956ef3326067);
        _testLambertW0WadMonoAround(0x35d9d57c965eb82c6);
        _testLambertW0WadMonoAround(0x184f520f19335f25d);
        _testLambertW0WadMonoAround(0x3c4bb8f445abe21a7);
        _testLambertW0WadMonoAround(0x573e3b3e06e208201);
        _testLambertW0WadMonoAround(0x184f520f19335f25d);
        _testLambertW0WadMonoAround(0x573e3b3e06e208201);
        _testLambertW0WadMonoAround(0x61e511ba00db632a4);
        _testLambertW0WadMonoAround(0x12731b97bde57933d);
        _testLambertW0WadMonoAround(0x79c29b05cf39be374);
        _testLambertW0WadMonoAround(0x390fcd4186ac250b3);
        _testLambertW0WadMonoAround(0x69c74b5975fd4832a);
        _testLambertW0WadMonoAround(0x59db219a7048121bd);
        _testLambertW0WadMonoAround(0x28f2adc4fab331d251);
        _testLambertW0WadMonoAround(0x7be91527cc31769c);
        _testLambertW0WadMonoAround(0x2ef215ae6701c40f);
        _testLambertW0WadMonoAround(0x1240541334cfadd81);
        _testLambertW0WadMonoAround(0x2a79eccb3d5f4faaed);
        _testLambertW0WadMonoAround(0x7470d50c23bfd30e0);
        _testLambertW0WadMonoAround(0x313386f14a7f95af9);
        _testLambertW0WadMonoAround(0x2a60f3b64c57088e9);
        _testLambertW0WadMonoAround(0x381298f7aa53edfe0);
        _testLambertW0WadMonoAround(0x5cbfac5d7a1770806);
        _testLambertW0WadMonoAround(0x19e46d1b5e6aba57e);
        _testLambertW0WadMonoAround(0x19ff86906ae47c70a);
        _testLambertW0WadMonoAround(0x164684654d9ca54ea1);
        _testLambertW0WadMonoAround(0x99337fa75e803139);
        _testLambertW0WadMonoAround(0x6fa0a50fcb8a95b97e);
        _testLambertW0WadMonoAround(0xa117a195e06c3fd531);
        _testLambertW0WadMonoAround(0x305da7073093bd8a07);
        _testLambertW0WadMonoAround(0x98582b07fd3c6b64);
        _testLambertW0WadMonoAround(0x1e824d2a367d9ce65);
        _testLambertW0WadMonoAround(0x7bea796d633b386a);
        _testLambertW0WadMonoAround(0x2fff5c38c6b2a2cd);
        _testLambertW0WadMonoAround(0x198af4e7ffee1df7627);
        _testLambertW0WadMonoAround(0x8ea8a7b6f7c7424d8d);
        _testLambertW0WadMonoAround(0x11e504fa805e54e2ed8);
        _testLambertW0WadMonoAround(0x3e5f2a7801badcdabd);
        _testLambertW0WadMonoAround(0x1b7aaad69ac8770a3be);
        _testLambertW0WadMonoAround(0x658acb00d525f3d345);
        _testLambertW0WadMonoAround(0xd994d6447146880183f);
        _testLambertW0WadMonoAround(0x2e07a342d7b1bc1a5ae);
    }

    function testLambertW0WadMonoDebug() public {
        unchecked {
            for (int256 i = -9; i <= 9; ++i) {
                _testLambertW0WadMonoAround(0x2e07a342d7b1bc1a5ae + i);
            }
        }
    }

    function _testLambertW0WadMonoAround(int256 x) internal {
        emit LogInt("x", x);
        emit LogUint("log2(x)", FixedPointMathLib.log2(uint256(x)));
        testLambertW0WadMonotonicallyIncreasingAround(x);
    }

    function testLambertW0WadMonotonicallyIncreasingAround2(uint96 t) public {
        int256 x = int256(uint256(t));
        testLambertW0WadMonotonicallyIncreasingAround(x);
        if (t & 0xff == 0xab) {
            _testLambertW0WadMonoFocus(x, 0, 0x1ffffffffffff, 0xffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 1, 0x1fffffffffffff, 0xffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 2, 0xfffffffffffffff, 0xffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 3, 0xffffffffffffffff, 0xfffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 4, 0xffffffffffffffff, 0xfffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 5, 0xffffffffffffffff, 0xffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 6, 0xffffffffffffffff, 0xffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 7, 0xffffffffffffffff, 0xfffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 8, 0xffffffffffffffff, 0xfffffffffffffffffff);
            _testLambertW0WadMonoFocus(x, 9, 0xffffffffffffffff, 0xffffffffffffffffffff);
        }
    }

    function _testLambertW0WadMonoFocus(int256 t, int256 i, int256 low, int256 mask) internal {
        int256 x;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, t)
            mstore(0x20, i)
            x := and(keccak256(0x00, 0x40), mask)
        }
        do {
            testLambertW0WadMonotonicallyIncreasingAround(x);
            x >>= 1;
        } while (x >= low);
    }

    function testLambertW0WadMonotonicallyIncreasingAround(int256 t) public {
        if (t < _LAMBERT_W0_MIN) t = _boundLambertW0WadInput(t);
        unchecked {
            int256 end = t + 2;
            for (int256 x = t - 2; x != end; ++x) {
                testLambertW0WadMonotonicallyIncreasing(x, x + 1);
            }
        }
    }

    function testLambertW0WadMonotonicallyIncreasing(int256 a, int256 b) public {
        if (a < _LAMBERT_W0_MIN) a = _boundLambertW0WadInput(a);
        if (b < _LAMBERT_W0_MIN) b = _boundLambertW0WadInput(b);
        if (a > b) {
            int256 t = b;
            b = a;
            a = t;
        }
        unchecked {
            uint256 gasBefore = gasleft();
            int256 w0a = FixedPointMathLib.lambertW0Wad(a);
            uint256 gasUsed = gasBefore - gasleft();
            int256 w0b = FixedPointMathLib.lambertW0Wad(b);
            bool success = w0a <= w0b;
            emit TestingLambertW0WadMonotonicallyIncreasing(a, b, w0a, w0b, success, gasUsed);
            if (!success) {
                emit LogUint("log2(a)", FixedPointMathLib.log2(uint256(a)));
                emit LogUint("log2(b)", FixedPointMathLib.log2(uint256(b)));
                emit LogUint("log2(w0a)", FixedPointMathLib.log2(uint256(w0a)));
                emit LogUint("log2(w0b)", FixedPointMathLib.log2(uint256(w0b)));
                assertTrue(success);
            }
        }
    }

    function _boundLambertW0WadInput(int256 x) internal pure returns (int256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(1, shl(1, not(x)))
        }
    }

    function testMulWad() public {
        assertEq(FixedPointMathLib.mulWad(2.5e18, 0.5e18), 1.25e18);
        assertEq(FixedPointMathLib.mulWad(3e18, 1e18), 3e18);
        assertEq(FixedPointMathLib.mulWad(369, 271), 0);
    }

    function testMulWadEdgeCases() public {
        assertEq(FixedPointMathLib.mulWad(0, 1e18), 0);
        assertEq(FixedPointMathLib.mulWad(1e18, 0), 0);
        assertEq(FixedPointMathLib.mulWad(0, 0), 0);
    }

    function testZZZ() public {
        emit LogInt("X", FixedPointMathLib.lnWad(0.5e18));
    }

    function testMulWadUp() public {
        assertEq(FixedPointMathLib.mulWadUp(2.5e18, 0.5e18), 1.25e18);
        assertEq(FixedPointMathLib.mulWadUp(3e18, 1e18), 3e18);
        assertEq(FixedPointMathLib.mulWadUp(369, 271), 1);
    }

    function testMulWadUpEdgeCases() public {
        assertEq(FixedPointMathLib.mulWadUp(0, 1e18), 0);
        assertEq(FixedPointMathLib.mulWadUp(1e18, 0), 0);
        assertEq(FixedPointMathLib.mulWadUp(0, 0), 0);
    }

    function testDivWad() public {
        assertEq(FixedPointMathLib.divWad(1.25e18, 0.5e18), 2.5e18);
        assertEq(FixedPointMathLib.divWad(3e18, 1e18), 3e18);
        assertEq(FixedPointMathLib.divWad(2, 100000000000000e18), 0);
    }

    function testDivWadEdgeCases() public {
        assertEq(FixedPointMathLib.divWad(0, 1e18), 0);
    }

    function testDivWadZeroDenominatorReverts() public {
        vm.expectRevert(FixedPointMathLib.DivWadFailed.selector);
        FixedPointMathLib.divWad(1e18, 0);
    }

    function testDivWadUp() public {
        assertEq(FixedPointMathLib.divWadUp(1.25e18, 0.5e18), 2.5e18);
        assertEq(FixedPointMathLib.divWadUp(3e18, 1e18), 3e18);
        assertEq(FixedPointMathLib.divWadUp(2, 100000000000000e18), 1);
        unchecked {
            for (uint256 i; i < 10; ++i) {
                assertEq(FixedPointMathLib.divWadUp(2, 100000000000000e18), 1);
            }
        }
    }

    function testDivWadUpEdgeCases() public {
        assertEq(FixedPointMathLib.divWadUp(0, 1e18), 0);
    }

    function testDivWadUpZeroDenominatorReverts() public {
        vm.expectRevert(FixedPointMathLib.DivWadFailed.selector);
        FixedPointMathLib.divWadUp(1e18, 0);
    }

    function testMulDiv() public {
        assertEq(FixedPointMathLib.mulDiv(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(FixedPointMathLib.mulDiv(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(FixedPointMathLib.mulDiv(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(FixedPointMathLib.mulDiv(369, 271, 1e2), 999);

        assertEq(FixedPointMathLib.mulDiv(1e27, 1e27, 2e27), 0.5e27);
        assertEq(FixedPointMathLib.mulDiv(1e18, 1e18, 2e18), 0.5e18);
        assertEq(FixedPointMathLib.mulDiv(1e8, 1e8, 2e8), 0.5e8);

        assertEq(FixedPointMathLib.mulDiv(2e27, 3e27, 2e27), 3e27);
        assertEq(FixedPointMathLib.mulDiv(3e18, 2e18, 3e18), 2e18);
        assertEq(FixedPointMathLib.mulDiv(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivEdgeCases() public {
        assertEq(FixedPointMathLib.mulDiv(0, 1e18, 1e18), 0);
        assertEq(FixedPointMathLib.mulDiv(1e18, 0, 1e18), 0);
        assertEq(FixedPointMathLib.mulDiv(0, 0, 1e18), 0);
    }

    function testMulDivZeroDenominatorReverts() public {
        vm.expectRevert(FixedPointMathLib.MulDivFailed.selector);
        FixedPointMathLib.mulDiv(1e18, 1e18, 0);
    }

    function testMulDivUp() public {
        assertEq(FixedPointMathLib.mulDivUp(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(FixedPointMathLib.mulDivUp(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(FixedPointMathLib.mulDivUp(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(FixedPointMathLib.mulDivUp(369, 271, 1e2), 1000);

        assertEq(FixedPointMathLib.mulDivUp(1e27, 1e27, 2e27), 0.5e27);
        assertEq(FixedPointMathLib.mulDivUp(1e18, 1e18, 2e18), 0.5e18);
        assertEq(FixedPointMathLib.mulDivUp(1e8, 1e8, 2e8), 0.5e8);

        assertEq(FixedPointMathLib.mulDivUp(2e27, 3e27, 2e27), 3e27);
        assertEq(FixedPointMathLib.mulDivUp(3e18, 2e18, 3e18), 2e18);
        assertEq(FixedPointMathLib.mulDivUp(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivUpEdgeCases() public {
        assertEq(FixedPointMathLib.mulDivUp(0, 1e18, 1e18), 0);
        assertEq(FixedPointMathLib.mulDivUp(1e18, 0, 1e18), 0);
        assertEq(FixedPointMathLib.mulDivUp(0, 0, 1e18), 0);
    }

    function testMulDivUpZeroDenominator() public {
        vm.expectRevert(FixedPointMathLib.MulDivFailed.selector);
        FixedPointMathLib.mulDivUp(1e18, 1e18, 0);
    }

    function testLnWad() public {
        assertEq(FixedPointMathLib.lnWad(1e18), 0);

        // Actual: 999999999999999999.8674576…
        assertEq(FixedPointMathLib.lnWad(2718281828459045235), 999999999999999999);

        // Actual: 2461607324344817917.963296…
        assertEq(FixedPointMathLib.lnWad(11723640096265400935), 2461607324344817918);
    }

    function testLnWadSmall() public {
        // Actual: -41446531673892822312.3238461…
        assertEq(FixedPointMathLib.lnWad(1), -41446531673892822313);

        // Actual: -37708862055609454006.40601608…
        assertEq(FixedPointMathLib.lnWad(42), -37708862055609454007);

        // Actual: -32236191301916639576.251880365581…
        assertEq(FixedPointMathLib.lnWad(1e4), -32236191301916639577);

        // Actual: -20723265836946411156.161923092…
        assertEq(FixedPointMathLib.lnWad(1e9), -20723265836946411157);
    }

    function testLnWadBig() public {
        // Actual: 135305999368893231589.070344787…
        assertEq(FixedPointMathLib.lnWad(2 ** 255 - 1), 135305999368893231589);

        // Actual: 76388489021297880288.605614463571…
        assertEq(FixedPointMathLib.lnWad(2 ** 170), 76388489021297880288);

        // Actual: 47276307437780177293.081865…
        assertEq(FixedPointMathLib.lnWad(2 ** 128), 47276307437780177293);
    }

    function testLnWadNegativeReverts() public {
        vm.expectRevert(FixedPointMathLib.LnWadUndefined.selector);
        FixedPointMathLib.lnWad(-1);
        FixedPointMathLib.lnWad(-2 ** 255);
    }

    function testLnWadOverflowReverts() public {
        vm.expectRevert(FixedPointMathLib.LnWadUndefined.selector);
        FixedPointMathLib.lnWad(0);
    }

    function testRPow() public {
        assertEq(FixedPointMathLib.rpow(0, 0, 0), 0);
        assertEq(FixedPointMathLib.rpow(1, 0, 0), 0);
        assertEq(FixedPointMathLib.rpow(0, 1, 0), 0);
        assertEq(FixedPointMathLib.rpow(0, 0, 1), 1);
        assertEq(FixedPointMathLib.rpow(1, 1, 0), 1);
        assertEq(FixedPointMathLib.rpow(1, 1, 1), 1);
        assertEq(FixedPointMathLib.rpow(2e27, 0, 1e27), 1e27);
        assertEq(FixedPointMathLib.rpow(2e27, 2, 1e27), 4e27);
        assertEq(FixedPointMathLib.rpow(2e18, 2, 1e18), 4e18);
        assertEq(FixedPointMathLib.rpow(2e8, 2, 1e8), 4e8);
        assertEq(FixedPointMathLib.rpow(8, 3, 1), 512);
    }

    function testRPowOverflowReverts() public {
        vm.expectRevert(FixedPointMathLib.RPowOverflow.selector);
        FixedPointMathLib.rpow(2, type(uint128).max, 1);
        FixedPointMathLib.rpow(type(uint128).max, 3, 1);
    }

    function testSqrt() public {
        assertEq(FixedPointMathLib.sqrt(0), 0);
        assertEq(FixedPointMathLib.sqrt(1), 1);
        assertEq(FixedPointMathLib.sqrt(2704), 52);
        assertEq(FixedPointMathLib.sqrt(110889), 333);
        assertEq(FixedPointMathLib.sqrt(32239684), 5678);
        unchecked {
            for (uint256 i = 100; i < 200; ++i) {
                assertEq(FixedPointMathLib.sqrt(i * i), i);
            }
        }
    }

    function testSqrtWad() public {
        assertEq(FixedPointMathLib.sqrtWad(0), 0);
        assertEq(FixedPointMathLib.sqrtWad(1), 10 ** 9);
        assertEq(FixedPointMathLib.sqrtWad(2), 1414213562);
        assertEq(FixedPointMathLib.sqrtWad(4), 2000000000);
        assertEq(FixedPointMathLib.sqrtWad(8), 2828427124);
        assertEq(FixedPointMathLib.sqrtWad(16), 4000000000);
        assertEq(FixedPointMathLib.sqrtWad(32), 5656854249);
        assertEq(FixedPointMathLib.sqrtWad(64), 8000000000);
        assertEq(FixedPointMathLib.sqrtWad(10 ** 18), 10 ** 18);
        assertEq(FixedPointMathLib.sqrtWad(4 * 10 ** 18), 2 * 10 ** 18);
        assertEq(FixedPointMathLib.sqrtWad(type(uint8).max), 15968719422);
        assertEq(FixedPointMathLib.sqrtWad(type(uint16).max), 255998046867);
        assertEq(FixedPointMathLib.sqrtWad(type(uint32).max), 65535999992370);
        assertEq(FixedPointMathLib.sqrtWad(type(uint64).max), 4294967295999999999);
        assertEq(FixedPointMathLib.sqrtWad(type(uint128).max), 18446744073709551615999999999);
        assertEq(
            FixedPointMathLib.sqrtWad(type(uint256).max),
            340282366920938463463374607431768211455000000000
        );
    }

    function testCbrt() public {
        assertEq(FixedPointMathLib.cbrt(0), 0);
        assertEq(FixedPointMathLib.cbrt(1), 1);
        assertEq(FixedPointMathLib.cbrt(2), 1);
        assertEq(FixedPointMathLib.cbrt(3), 1);
        assertEq(FixedPointMathLib.cbrt(9), 2);
        assertEq(FixedPointMathLib.cbrt(27), 3);
        assertEq(FixedPointMathLib.cbrt(80), 4);
        assertEq(FixedPointMathLib.cbrt(81), 4);
        assertEq(FixedPointMathLib.cbrt(10 ** 18), 10 ** 6);
        assertEq(FixedPointMathLib.cbrt(8 * 10 ** 18), 2 * 10 ** 6);
        assertEq(FixedPointMathLib.cbrt(9 * 10 ** 18), 2080083);
        assertEq(FixedPointMathLib.cbrt(type(uint8).max), 6);
        assertEq(FixedPointMathLib.cbrt(type(uint16).max), 40);
        assertEq(FixedPointMathLib.cbrt(type(uint32).max), 1625);
        assertEq(FixedPointMathLib.cbrt(type(uint64).max), 2642245);
        assertEq(FixedPointMathLib.cbrt(type(uint128).max), 6981463658331);
        assertEq(FixedPointMathLib.cbrt(type(uint256).max), 48740834812604276470692694);
    }

    function testCbrtWad() public {
        assertEq(FixedPointMathLib.cbrtWad(0), 0);
        assertEq(FixedPointMathLib.cbrtWad(1), 10 ** 12);
        assertEq(FixedPointMathLib.cbrtWad(2), 1259921049894);
        assertEq(FixedPointMathLib.cbrtWad(3), 1442249570307);
        assertEq(FixedPointMathLib.cbrtWad(9), 2080083823051);
        assertEq(FixedPointMathLib.cbrtWad(27), 3000000000000);
        assertEq(FixedPointMathLib.cbrtWad(80), 4308869380063);
        assertEq(FixedPointMathLib.cbrtWad(81), 4326748710922);
        assertEq(FixedPointMathLib.cbrtWad(10 ** 18), 10 ** 18);
        assertEq(FixedPointMathLib.cbrtWad(8 * 10 ** 18), 2 * 10 ** 18);
        assertEq(FixedPointMathLib.cbrtWad(9 * 10 ** 18), 2080083823051904114);
        assertEq(FixedPointMathLib.cbrtWad(type(uint8).max), 6341325705384);
        assertEq(FixedPointMathLib.cbrtWad(type(uint16).max), 40317268530317);
        assertEq(FixedPointMathLib.cbrtWad(type(uint32).max), 1625498677089280);
        assertEq(FixedPointMathLib.cbrtWad(type(uint64).max), 2642245949629133047);
        assertEq(FixedPointMathLib.cbrtWad(type(uint128).max), 6981463658331559092288464);
        assertEq(
            FixedPointMathLib.cbrtWad(type(uint256).max), 48740834812604276470692694000000000000
        );
    }

    function testLog2() public {
        assertEq(FixedPointMathLib.log2(0), 0);
        assertEq(FixedPointMathLib.log2(2), 1);
        assertEq(FixedPointMathLib.log2(4), 2);
        assertEq(FixedPointMathLib.log2(1024), 10);
        assertEq(FixedPointMathLib.log2(1048576), 20);
        assertEq(FixedPointMathLib.log2(1073741824), 30);
        for (uint256 i = 1; i < 255; i++) {
            assertEq(FixedPointMathLib.log2((1 << i) - 1), i - 1);
            assertEq(FixedPointMathLib.log2((1 << i)), i);
            assertEq(FixedPointMathLib.log2((1 << i) + 1), i);
        }
    }

    function testLog2Differential(uint256 x) public {
        assertEq(FixedPointMathLib.log2(x), _log2Original(x));
    }

    function _log2Original(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function testLog2Up() public {
        assertEq(FixedPointMathLib.log2Up(0), 0);
        assertEq(FixedPointMathLib.log2Up(1), 0);
        assertEq(FixedPointMathLib.log2Up(2), 1);
        assertEq(FixedPointMathLib.log2Up(2 + 1), 2);
        assertEq(FixedPointMathLib.log2Up(4), 2);
        assertEq(FixedPointMathLib.log2Up(4 + 1), 3);
        assertEq(FixedPointMathLib.log2Up(4 + 2), 3);
        assertEq(FixedPointMathLib.log2Up(1024), 10);
        assertEq(FixedPointMathLib.log2Up(1024 + 1), 11);
        assertEq(FixedPointMathLib.log2Up(1048576), 20);
        assertEq(FixedPointMathLib.log2Up(1048576 + 1), 21);
        assertEq(FixedPointMathLib.log2Up(1073741824), 30);
        assertEq(FixedPointMathLib.log2Up(1073741824 + 1), 31);
        for (uint256 i = 2; i < 255; i++) {
            assertEq(FixedPointMathLib.log2Up((1 << i) - 1), i);
            assertEq(FixedPointMathLib.log2Up((1 << i)), i);
            assertEq(FixedPointMathLib.log2Up((1 << i) + 1), i + 1);
        }
    }

    function testAvg() public {
        assertEq(FixedPointMathLib.avg(uint256(5), uint256(6)), uint256(5));
        assertEq(FixedPointMathLib.avg(uint256(0), uint256(1)), uint256(0));
        assertEq(FixedPointMathLib.avg(uint256(45645465), uint256(4846513)), uint256(25245989));
    }

    function testAvgSigned() public {
        assertEq(FixedPointMathLib.avg(int256(5), int256(6)), int256(5));
        assertEq(FixedPointMathLib.avg(int256(0), int256(1)), int256(0));
        assertEq(FixedPointMathLib.avg(int256(45645465), int256(4846513)), int256(25245989));

        assertEq(FixedPointMathLib.avg(int256(5), int256(-6)), int256(-1));
        assertEq(FixedPointMathLib.avg(int256(0), int256(-1)), int256(-1));
        assertEq(FixedPointMathLib.avg(int256(45645465), int256(-4846513)), int256(20399476));
    }

    function testAvgEdgeCase() public {
        assertEq(FixedPointMathLib.avg(uint256(2 ** 256 - 1), uint256(1)), uint256(2 ** 255));
        assertEq(FixedPointMathLib.avg(uint256(2 ** 256 - 1), uint256(10)), uint256(2 ** 255 + 4));
        assertEq(
            FixedPointMathLib.avg(uint256(2 ** 256 - 1), uint256(2 ** 256 - 1)),
            uint256(2 ** 256 - 1)
        );
    }

    function testAbs() public {
        assertEq(FixedPointMathLib.abs(0), 0);
        assertEq(FixedPointMathLib.abs(-5), 5);
        assertEq(FixedPointMathLib.abs(5), 5);
        assertEq(FixedPointMathLib.abs(-1155656654), 1155656654);
        assertEq(FixedPointMathLib.abs(621356166516546561651), 621356166516546561651);
    }

    function testDist() public {
        assertEq(FixedPointMathLib.dist(0, 0), 0);
        assertEq(FixedPointMathLib.dist(-5, -4), 1);
        assertEq(FixedPointMathLib.dist(5, 46), 41);
        assertEq(FixedPointMathLib.dist(46, 5), 41);
        assertEq(FixedPointMathLib.dist(-1155656654, 6544844), 1162201498);
        assertEq(FixedPointMathLib.dist(-848877, -8447631456), 8446782579);
    }

    function testDistEdgeCases() public {
        assertEq(FixedPointMathLib.dist(type(int256).min, type(int256).max), type(uint256).max);
        assertEq(
            FixedPointMathLib.dist(type(int256).min, 0),
            0x8000000000000000000000000000000000000000000000000000000000000000
        );
        assertEq(
            FixedPointMathLib.dist(type(int256).max, 5),
            0x7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
        );
        assertEq(
            FixedPointMathLib.dist(type(int256).min, -5),
            0x7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
        );
    }

    function testAbsEdgeCases() public {
        assertEq(FixedPointMathLib.abs(-(2 ** 255 - 1)), (2 ** 255 - 1));
        assertEq(FixedPointMathLib.abs((2 ** 255 - 1)), (2 ** 255 - 1));
    }

    function testGcd() public {
        assertEq(FixedPointMathLib.gcd(0, 0), 0);
        assertEq(FixedPointMathLib.gcd(85, 0), 85);
        assertEq(FixedPointMathLib.gcd(0, 2), 2);
        assertEq(FixedPointMathLib.gcd(56, 45), 1);
        assertEq(FixedPointMathLib.gcd(12, 28), 4);
        assertEq(FixedPointMathLib.gcd(12, 1), 1);
        assertEq(FixedPointMathLib.gcd(486516589451122, 48656), 2);
        assertEq(FixedPointMathLib.gcd(2 ** 254 - 4, 2 ** 128 - 1), 15);
        assertEq(FixedPointMathLib.gcd(3, 26017198113384995722614372765093167890), 1);
        unchecked {
            for (uint256 i = 2; i < 10; ++i) {
                assertEq(FixedPointMathLib.gcd(31 * (1 << i), 31), 31);
            }
        }
    }

    function testFullMulDiv() public {
        assertEq(FixedPointMathLib.fullMulDiv(0, 0, 1), 0);
        assertEq(FixedPointMathLib.fullMulDiv(4, 4, 2), 8);
        assertEq(FixedPointMathLib.fullMulDiv(2 ** 200, 2 ** 200, 2 ** 200), 2 ** 200);
    }

    function testFullMulDivUpRevertsIfRoundedUpResultOverflowsCase1() public {
        vm.expectRevert(FixedPointMathLib.FullMulDivFailed.selector);
        FixedPointMathLib.fullMulDivUp(
            535006138814359, 432862656469423142931042426214547535783388063929571229938474969, 2
        );
    }

    function testFullMulDivUpRevertsIfRoundedUpResultOverflowsCase2() public {
        vm.expectRevert(FixedPointMathLib.FullMulDivFailed.selector);
        FixedPointMathLib.fullMulDivUp(
            115792089237316195423570985008687907853269984659341747863450311749907997002549,
            115792089237316195423570985008687907853269984659341747863450311749907997002550,
            115792089237316195423570985008687907853269984653042931687443039491902864365164
        );
    }

    function testFullMulDiv(uint256 a, uint256 b, uint256 d) public returns (uint256 result) {
        if (d == 0) {
            vm.expectRevert(FixedPointMathLib.FullMulDivFailed.selector);
            FixedPointMathLib.fullMulDiv(a, b, d);
            return 0;
        }

        // Compute a * b in Chinese Remainder Basis
        uint256 expectedA;
        uint256 expectedB;
        unchecked {
            expectedA = a * b;
            expectedB = mulmod(a, b, 2 ** 256 - 1);
        }

        // Construct a * b
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
        if (prod1 >= d) {
            vm.expectRevert(FixedPointMathLib.FullMulDivFailed.selector);
            FixedPointMathLib.fullMulDiv(a, b, d);
            return 0;
        }

        uint256 q = FixedPointMathLib.fullMulDiv(a, b, d);
        uint256 r = mulmod(a, b, d);

        // Compute q * d + r in Chinese Remainder Basis
        uint256 actualA;
        uint256 actualB;
        unchecked {
            actualA = q * d + r;
            actualB = addmod(mulmod(q, d, 2 ** 256 - 1), r, 2 ** 256 - 1);
        }

        assertEq(actualA, expectedA);
        assertEq(actualB, expectedB);
        return q;
    }

    function testFullMulDivUp(uint256 a, uint256 b, uint256 d) public {
        uint256 fullMulDivResult = testFullMulDiv(a, b, d);
        if (fullMulDivResult != 0) {
            uint256 expectedResult = fullMulDivResult;
            if (mulmod(a, b, d) > 0) {
                if (!(fullMulDivResult < type(uint256).max)) {
                    vm.expectRevert(FixedPointMathLib.FullMulDivFailed.selector);
                    FixedPointMathLib.fullMulDivUp(a, b, d);
                    return;
                }
                expectedResult++;
            }
            assertEq(FixedPointMathLib.fullMulDivUp(a, b, d), expectedResult);
        }
    }

    function testMulWad(uint256 x, uint256 y) public {
        // Ignore cases where x * y overflows.
        unchecked {
            if (x != 0 && (x * y) / x != y) return;
        }

        uint256 result = FixedPointMathLib.mulWad(x, y);
        assertEq(result, (x * y) / 1e18);
        assertEq(FixedPointMathLib.rawMulWad(x, y), result);
    }

    function testMulWadOverflowReverts(uint256 x, uint256 y) public {
        // Ignore cases where x * y does not overflow.
        unchecked {
            vm.assume(x != 0 && (x * y) / x != y);
        }
        vm.expectRevert(FixedPointMathLib.MulWadFailed.selector);
        FixedPointMathLib.mulWad(x, y);
    }

    function testMulWadUp(uint256 x, uint256 y) public {
        // Ignore cases where x * y overflows.
        unchecked {
            if (x != 0 && (x * y) / x != y) return;
        }

        assertEq(FixedPointMathLib.mulWadUp(x, y), x * y == 0 ? 0 : (x * y - 1) / 1e18 + 1);
    }

    function testMulWadUpOverflowReverts(uint256 x, uint256 y) public {
        // Ignore cases where x * y does not overflow.
        unchecked {
            vm.assume(x != 0 && !((x * y) / x == y));
        }
        vm.expectRevert(FixedPointMathLib.MulWadFailed.selector);
        FixedPointMathLib.mulWadUp(x, y);
    }

    function testDivWad(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD overflows or y is 0.
        unchecked {
            if (y == 0 || (x != 0 && (x * 1e18) / 1e18 != x)) return;
        }

        uint256 result = FixedPointMathLib.divWad(x, y);
        assertEq(result, (x * 1e18) / y);
        assertEq(FixedPointMathLib.rawDivWad(x, y), result);
    }

    function testDivWadOverflowReverts(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD does not overflow or y is 0.
        unchecked {
            vm.assume(y != 0 && (x * 1e18) / 1e18 != x);
        }
        vm.expectRevert(FixedPointMathLib.DivWadFailed.selector);
        FixedPointMathLib.divWad(x, y);
    }

    function testDivWadZeroDenominatorReverts(uint256 x) public {
        vm.expectRevert(FixedPointMathLib.DivWadFailed.selector);
        FixedPointMathLib.divWad(x, 0);
    }

    function testDivWadUp(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD overflows or y is 0.
        unchecked {
            if (y == 0 || (x != 0 && (x * 1e18) / 1e18 != x)) return;
        }

        assertEq(FixedPointMathLib.divWadUp(x, y), x == 0 ? 0 : (x * 1e18 - 1) / y + 1);
    }

    function testDivWadUpOverflowReverts(uint256 x, uint256 y) public {
        // Ignore cases where x * WAD does not overflow or y is 0.
        unchecked {
            vm.assume(y != 0 && (x * 1e18) / 1e18 != x);
        }
        vm.expectRevert(FixedPointMathLib.DivWadFailed.selector);
        FixedPointMathLib.divWadUp(x, y);
    }

    function testDivWadUpZeroDenominatorReverts(uint256 x) public {
        vm.expectRevert(FixedPointMathLib.DivWadFailed.selector);
        FixedPointMathLib.divWadUp(x, 0);
    }

    function testMulDiv(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(FixedPointMathLib.mulDiv(x, y, denominator), (x * y) / denominator);
    }

    function testMulDivOverflowReverts(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y does not overflow or denominator is 0.
        unchecked {
            vm.assume(denominator != 0 && x != 0 && (x * y) / x != y);
        }
        vm.expectRevert(FixedPointMathLib.MulDivFailed.selector);
        FixedPointMathLib.mulDiv(x, y, denominator);
    }

    function testMulDivZeroDenominatorReverts(uint256 x, uint256 y) public {
        vm.expectRevert(FixedPointMathLib.MulDivFailed.selector);
        FixedPointMathLib.mulDiv(x, y, 0);
    }

    function testMulDivUp(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(
            FixedPointMathLib.mulDivUp(x, y, denominator),
            x * y == 0 ? 0 : (x * y - 1) / denominator + 1
        );
    }

    function testMulDivUpOverflowReverts(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y does not overflow or denominator is 0.
        unchecked {
            vm.assume(denominator != 0 && x != 0 && (x * y) / x != y);
        }
        vm.expectRevert(FixedPointMathLib.MulDivFailed.selector);
        FixedPointMathLib.mulDivUp(x, y, denominator);
    }

    function testMulDivUpZeroDenominatorReverts(uint256 x, uint256 y) public {
        vm.expectRevert(FixedPointMathLib.MulDivFailed.selector);
        FixedPointMathLib.mulDivUp(x, y, 0);
    }

    function testCbrt(uint256 x) public {
        uint256 root = FixedPointMathLib.cbrt(x);
        uint256 next = root + 1;

        // Ignore cases where `next * next * next` or `next * next` overflows.
        unchecked {
            if (next * next * next < next * next) return;
            if (next * next < next) return;
        }

        assertTrue(root * root * root <= x && next * next * next > x);
    }

    function testCbrtWad(uint256 x) public {
        uint256 result = FixedPointMathLib.cbrtWad(x);
        uint256 floor = FixedPointMathLib.cbrt(x);
        assertTrue(result >= floor * 10 ** 12 && result <= (floor + 1) * 10 ** 12);
        assertEq(result / 10 ** 12, floor);
    }

    function testCbrtBack(uint256 x) public {
        unchecked {
            x = _bound(x, 0, 48740834812604276470692694);
            while (x != 0) {
                assertEq(FixedPointMathLib.cbrt(x * x * x), x);
                x >>= 1;
            }
        }
    }

    function testSqrt(uint256 x) public {
        uint256 root = FixedPointMathLib.sqrt(x);
        uint256 next = root + 1;

        // Ignore cases where `next * next` overflows.
        unchecked {
            if (next * next < next) return;
        }

        assertTrue(root * root <= x && next * next > x);
    }

    function testSqrtWad(uint256 x) public {
        uint256 result = FixedPointMathLib.sqrtWad(x);
        uint256 floor = FixedPointMathLib.sqrt(x);
        assertTrue(result >= floor * 10 ** 9 && result <= (floor + 1) * 10 ** 9);
        assertEq(result / 10 ** 9, floor);
    }

    function testSqrtBack(uint256 x) public {
        unchecked {
            x >>= 128;
            while (x != 0) {
                assertEq(FixedPointMathLib.sqrt(x * x), x);
                x >>= 1;
            }
        }
    }

    function testSqrtHashed(uint256 x) public {
        testSqrtBack(uint256(keccak256(abi.encode(x))));
    }

    function testSqrtHashedSingle() public {
        testSqrtHashed(123);
    }

    function testMin(uint256 x, uint256 y) public {
        uint256 z = x < y ? x : y;
        assertEq(FixedPointMathLib.min(x, y), z);
    }

    function testMinBrutalized(uint256 x, uint256 y) public {
        uint32 xCasted;
        uint32 yCasted;
        /// @solidity memory-safe-assembly
        assembly {
            xCasted := x
            yCasted := y
        }
        uint256 expected = xCasted < yCasted ? xCasted : yCasted;
        assertEq(FixedPointMathLib.min(xCasted, yCasted), expected);
        assertEq(FixedPointMathLib.min(uint32(x), uint32(y)), expected);
        expected = uint32(x) < uint32(y) ? uint32(x) : uint32(y);
        assertEq(FixedPointMathLib.min(xCasted, yCasted), expected);
    }

    function testMinSigned(int256 x, int256 y) public {
        int256 z = x < y ? x : y;
        assertEq(FixedPointMathLib.min(x, y), z);
    }

    function testMax(uint256 x, uint256 y) public {
        uint256 z = x > y ? x : y;
        assertEq(FixedPointMathLib.max(x, y), z);
    }

    function testMaxSigned(int256 x, int256 y) public {
        int256 z = x > y ? x : y;
        assertEq(FixedPointMathLib.max(x, y), z);
    }

    function testMaxCasted(uint32 x, uint32 y, uint256 brutalizer) public {
        uint32 z = x > y ? x : y;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, brutalizer)
            mstore(0x20, 1)
            x := or(shl(32, keccak256(0x00, 0x40)), x)
            mstore(0x20, 2)
            y := or(shl(32, keccak256(0x00, 0x40)), y)
        }
        assertTrue(FixedPointMathLib.max(x, y) == z);
    }

    function testZeroFloorSub(uint256 x, uint256 y) public {
        uint256 z = x > y ? x - y : 0;
        assertEq(FixedPointMathLib.zeroFloorSub(x, y), z);
    }

    function testZeroFloorSubCasted(uint32 x, uint32 y, uint256 brutalizer) public {
        uint256 z = x > y ? x - y : 0;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, brutalizer)
            mstore(0x20, 1)
            x := or(shl(32, keccak256(0x00, 0x40)), x)
            mstore(0x20, 2)
            y := or(shl(32, keccak256(0x00, 0x40)), y)
        }
        assertTrue(FixedPointMathLib.zeroFloorSub(x, y) == z);
    }

    function testDist(int256 x, int256 y) public {
        uint256 z;
        unchecked {
            if (x > y) {
                z = uint256(x - y);
            } else {
                z = uint256(y - x);
            }
        }
        assertEq(FixedPointMathLib.dist(x, y), z);
    }

    function testAbs(int256 x) public {
        uint256 z = uint256(x);
        if (x < 0) {
            if (x == type(int256).min) {
                z = uint256(type(int256).max) + 1;
            } else {
                z = uint256(-x);
            }
        }
        assertEq(FixedPointMathLib.abs(x), z);
    }

    function testGcd(uint256 x, uint256 y) public {
        assertEq(FixedPointMathLib.gcd(x, y), _gcd(x, y));
    }

    function testClamp(uint256 x, uint256 minValue, uint256 maxValue) public {
        uint256 clamped = x;
        if (clamped < minValue) {
            clamped = minValue;
        }
        if (clamped > maxValue) {
            clamped = maxValue;
        }
        assertEq(FixedPointMathLib.clamp(x, minValue, maxValue), clamped);
    }

    function testClampSigned(int256 x, int256 minValue, int256 maxValue) public {
        int256 clamped = x;
        if (clamped < minValue) {
            clamped = minValue;
        }
        if (clamped > maxValue) {
            clamped = maxValue;
        }
        assertEq(FixedPointMathLib.clamp(x, minValue, maxValue), clamped);
    }

    function testFactorial() public {
        uint256 result = 1;
        assertEq(FixedPointMathLib.factorial(0), result);
        unchecked {
            for (uint256 i = 1; i != 58; ++i) {
                result = result * i;
                assertEq(FixedPointMathLib.factorial(i), result);
            }
        }
        vm.expectRevert(FixedPointMathLib.FactorialOverflow.selector);
        FixedPointMathLib.factorial(58);
    }

    function testFactorialOriginal() public {
        uint256 result = 1;
        assertEq(_factorialOriginal(0), result);
        unchecked {
            for (uint256 i = 1; i != 58; ++i) {
                result = result * i;
                assertEq(_factorialOriginal(i), result);
            }
        }
    }

    function _factorialOriginal(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            for {} x {} {
                result := mul(result, x)
                x := sub(x, 1)
            }
        }
    }

    function _gcd(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (y == 0) {
            return x;
        } else {
            return _gcd(y, x % y);
        }
    }

    function testRawAdd(uint256 x, uint256 y) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := add(x, y)
        }
        assertEq(FixedPointMathLib.rawAdd(x, y), z);
    }

    function testRawAdd(int256 x, int256 y) public {
        int256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := add(x, y)
        }
        assertEq(FixedPointMathLib.rawAdd(x, y), z);
    }

    function testRawSub(uint256 x, uint256 y) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := sub(x, y)
        }
        assertEq(FixedPointMathLib.rawSub(x, y), z);
    }

    function testRawSub(int256 x, int256 y) public {
        int256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := sub(x, y)
        }
        assertEq(FixedPointMathLib.rawSub(x, y), z);
    }

    function testRawMul(uint256 x, uint256 y) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
        }
        assertEq(FixedPointMathLib.rawMul(x, y), z);
    }

    function testRawMul(int256 x, int256 y) public {
        int256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(x, y)
        }
        assertEq(FixedPointMathLib.rawMul(x, y), z);
    }

    function testRawDiv(uint256 x, uint256 y) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
        assertEq(FixedPointMathLib.rawDiv(x, y), z);
    }

    function testRawSDiv(int256 x, int256 y) public {
        int256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
        assertEq(FixedPointMathLib.rawSDiv(x, y), z);
    }

    function testRawMod(uint256 x, uint256 y) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
        assertEq(FixedPointMathLib.rawMod(x, y), z);
    }

    function testRawSMod(int256 x, int256 y) public {
        int256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
        assertEq(FixedPointMathLib.rawSMod(x, y), z);
    }

    function testRawAddMod(uint256 x, uint256 y, uint256 denominator) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, denominator)
        }
        assertEq(FixedPointMathLib.rawAddMod(x, y, denominator), z);
    }

    function testRawMulMod(uint256 x, uint256 y, uint256 denominator) public {
        uint256 z;
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, denominator)
        }
        assertEq(FixedPointMathLib.rawMulMod(x, y, denominator), z);
    }

    function testLog10() public {
        assertEq(FixedPointMathLib.log10(0), 0);
        assertEq(FixedPointMathLib.log10(1), 0);
        assertEq(FixedPointMathLib.log10(type(uint256).max), 77);
        unchecked {
            for (uint256 i = 1; i <= 77; ++i) {
                uint256 x = 10 ** i;
                assertEq(FixedPointMathLib.log10(x), i);
                assertEq(FixedPointMathLib.log10(x - 1), i - 1);
                assertEq(FixedPointMathLib.log10(x + 1), i);
            }
        }
    }

    function testLog10(uint256 i, uint256 j) public {
        i = _bound(i, 0, 77);
        uint256 low = 10 ** i;
        uint256 high = i == 77 ? type(uint256).max : (10 ** (i + 1)) - 1;
        uint256 x = _bound(j, low, high);
        assertEq(FixedPointMathLib.log10(x), i);
    }

    function testLog10Up() public {
        assertEq(FixedPointMathLib.log10Up(0), 0);
        assertEq(FixedPointMathLib.log10Up(1), 0);
        assertEq(FixedPointMathLib.log10Up(9), 1);
        assertEq(FixedPointMathLib.log10Up(10), 1);
        assertEq(FixedPointMathLib.log10Up(99), 2);
        assertEq(FixedPointMathLib.log10Up(100), 2);
        assertEq(FixedPointMathLib.log10Up(999), 3);
        assertEq(FixedPointMathLib.log10Up(1000), 3);
        assertEq(FixedPointMathLib.log10Up(10 ** 77), 77);
        assertEq(FixedPointMathLib.log10Up(10 ** 77 + 1), 78);
        assertEq(FixedPointMathLib.log10Up(type(uint256).max), 78);
    }

    function testLog256() public {
        assertEq(FixedPointMathLib.log256(0), 0);
        assertEq(FixedPointMathLib.log256(1), 0);
        assertEq(FixedPointMathLib.log256(256), 1);
        assertEq(FixedPointMathLib.log256(type(uint256).max), 31);
        unchecked {
            for (uint256 i = 1; i <= 31; ++i) {
                uint256 x = 256 ** i;
                assertEq(FixedPointMathLib.log256(x), i);
                assertEq(FixedPointMathLib.log256(x - 1), i - 1);
                assertEq(FixedPointMathLib.log256(x + 1), i);
            }
        }
    }

    function testLog256(uint256 i, uint256 j) public {
        i = _bound(i, 0, 31);
        uint256 low = 256 ** i;
        uint256 high = i == 31 ? type(uint256).max : (256 ** (i + 1)) - 1;
        uint256 x = _bound(j, low, high);
        assertEq(FixedPointMathLib.log256(x), i);
    }

    function testLog256Up() public {
        assertEq(FixedPointMathLib.log256Up(0), 0);
        assertEq(FixedPointMathLib.log256Up(0x01), 0);
        assertEq(FixedPointMathLib.log256Up(0x02), 1);
        assertEq(FixedPointMathLib.log256Up(0xff), 1);
        assertEq(FixedPointMathLib.log256Up(0x0100), 1);
        assertEq(FixedPointMathLib.log256Up(0x0101), 2);
        assertEq(FixedPointMathLib.log256Up(0xffff), 2);
        assertEq(FixedPointMathLib.log256Up(0x010000), 2);
        assertEq(FixedPointMathLib.log256Up(0x010001), 3);
        assertEq(FixedPointMathLib.log256Up(type(uint256).max - 1), 32);
        assertEq(FixedPointMathLib.log256Up(type(uint256).max), 32);
    }

    function testSci() public {
        _testSci(0, 0, 0);
        _testSci(1, 1, 0);
        _testSci(13, 13, 0);
        _testSci(130, 13, 1);
        _testSci(1300, 13, 2);
        unchecked {
            uint256 a = 103;
            uint256 exponent = 0;
            uint256 m = 1;
            uint256 n = 78 - FixedPointMathLib.log10Up(a);
            for (uint256 i; i < n; ++i) {
                _testSci(a * m, a, exponent);
                exponent += 1;
                m *= 10;
            }
        }
        _testSci(10 ** 77, 1, 77);
        _testSci(2 * (10 ** 76), 2, 76);
        _testSci(9 * (10 ** 76), 9, 76);
        unchecked {
            for (uint256 i; i < 32; ++i) {
                testSci(11 + i * i * 100);
            }
            for (uint256 i; i < 500; ++i) {
                _testSci(0, 0, 0);
            }
        }
        unchecked {
            uint256 x = 30000000000000000000000000000000000000000000000001;
            _testSci(x, x, 0);
        }
    }

    function testSci(uint256 a) public {
        unchecked {
            while (a % 10 == 0) a = _random();
            uint256 exponent = 0;
            uint256 m = 1;
            uint256 n = 78 - FixedPointMathLib.log10Up(a);
            for (uint256 i; i < n; ++i) {
                _testSci(a * m, a, exponent);
                uint256 x = a * 10 ** exponent;
                assertEq(x, a * m);
                exponent += 1;
                m *= 10;
            }
        }
    }

    function testSci2(uint256 x) public {
        unchecked {
            (uint256 mantissa, uint256 exponent) = FixedPointMathLib.sci(x);
            assertEq(x % 10 ** exponent, 0);
            if (x != 0) {
                assertTrue(x % 10 ** (exponent + 1) > 0);
                assertTrue(mantissa % 10 != 0);
            } else {
                assertEq(mantissa, 0);
                assertEq(exponent, 0);
            }
        }
    }

    function _testSci(uint256 x, uint256 expectedMantissa, uint256 expectedExponent) internal {
        (uint256 mantissa, uint256 exponent) = FixedPointMathLib.sci(x);
        assertEq(mantissa, expectedMantissa);
        assertEq(exponent, expectedExponent);
    }

    function testPackUnpackSci(uint256) public {
        unchecked {
            uint256 x = (_random() & 0x1) * 10 ** (_random() % 70);
            uint8 packed = uint8(FixedPointMathLib.packSci(x));
            uint256 unpacked = FixedPointMathLib.unpackSci(packed);
            assertEq(unpacked, x);
        }
        unchecked {
            uint256 x = (_random() & 0x1ff) * 10 ** (_random() % 70);
            uint16 packed = uint16(FixedPointMathLib.packSci(x));
            uint256 unpacked = FixedPointMathLib.unpackSci(packed);
            assertEq(unpacked, x);
        }
        unchecked {
            uint256 x = (_random() & 0x1ffffff) * 10 ** (_random() % 70);
            uint32 packed = uint32(FixedPointMathLib.packSci(x));
            uint256 unpacked = FixedPointMathLib.unpackSci(packed);
            assertEq(unpacked, x);
        }
        unchecked {
            uint256 x = (_random() & 0x1ffffffffffffff) * 10 ** (_random() % 60);
            uint64 packed = uint64(FixedPointMathLib.packSci(x));
            uint256 unpacked = FixedPointMathLib.unpackSci(packed);
            assertEq(unpacked, x);
        }
        unchecked {
            uint256 x = (_random() * 10 ** (_random() % 78)) & ((1 << 249) - 1);
            uint256 packed = FixedPointMathLib.packSci(x);
            uint256 unpacked = FixedPointMathLib.unpackSci(packed);
            assertEq(unpacked, x);
        }
    }

    function testPackUnpackSci() public {
        uint256 mantissaSize = 249;
        unchecked {
            for (uint256 i; i <= mantissaSize; ++i) {
                uint256 x = (1 << i) - 1;
                uint256 packed = FixedPointMathLib.packSci(x);
                uint256 unpacked = FixedPointMathLib.unpackSci(packed);
                assertEq(unpacked, x);
            }
        }
        unchecked {
            uint256 x = (1 << (mantissaSize + 1)) - 1;
            vm.expectRevert(FixedPointMathLib.MantissaOverflow.selector);
            FixedPointMathLib.packSci(x);
        }
    }
}
