"""CHIM ORomance Bridge - writes build/CHIMORomanceBridge.esp and build/SEQ/CHIMORomanceBridge.seq.

The plugin has no art or world edits, so it is generated here byte by byte instead of
being saved from the Creation Kit or xEdit. Running this again gives the same files.

  TES4 header   ESL flag (0x200), author SaurOff, master Skyrim.esm, form version 44
  0x800 QUST    COR_BridgeQuest   - script COR_Bridge  (the AI's actions -> ORomance Plus)
  0x801 QUST    COR_EventsQuest   - script COR_Events  (state for the server, wives talking,
                                    marital duty, Fertility Mode)
  0x802 QUST    COR_MCMQuest      - script COR_MCM (MCM Helper menu) and a player alias with
                                    SkyUI's SKI_PlayerLoadGameAlias, which MCM Helper needs
  0x803 QUST    COR_DialogueQuest - holds the proposal dialogue
  0x804 DLBR    COR_ProposeBranch - top-level player branch
  0x805 DIAL    COR_Propose       - "(Amulet of Mara) Will you marry me?"
  0x806 INFO    (in 0x805)        - the reply; end fragment COR_TIF_Propose

All quests are start-game-enabled (DNAM flags 0x0111), so they also start on an existing
save. The dialogue copies the layout of Skyrim.esm's own courting line
(RelationshipMarriageIntroDialogueCourtingIntro, INFO 000CD86F) and its conditions:
the player wears the Amulet of Mara and the NPC is at least a friend; added: not married
to the player yet. A start-game-enabled quest with dialogue is listed in the .seq file.
Run: python3 -I make_esp.py [output folder]
"""
import os, struct, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build")
OUT = os.path.join(OUT_DIR, "CHIMORomanceBridge.esp")
SEQ = os.path.join(OUT_DIR, "SEQ", "CHIMORomanceBridge.seq")

PROMPT = "(Amulet of Mara) Will you marry me?"
REPLY = " "  # silent: ORomance makes the NPC say the vanilla acceptance


def sub(tag, data):
    return tag + struct.pack('<H', len(data)) + data


def wstr(s):
    b = s.encode()
    return struct.pack('<H', len(b)) + b


def zstr(s):
    return s.encode('utf-8') + b'\0'


def record(tag, fid, body):
    return tag + struct.pack('<IIIIHH', len(body), 0, fid, 0, 44, 0) + body


def group(label, gtype, content):
    lab = label if isinstance(label, bytes) else struct.pack('<I', label)
    return b'GRUP' + struct.pack('<I', 24 + len(content)) + lab + struct.pack('<iHHHH', gtype, 0, 0, 0, 0) + content


def script(name):
    return wstr(name) + b'\x00' + struct.pack('<H', 0)  # status 0, no properties


def vmad_plain(name):
    return struct.pack('<hhH', 5, 2, 1) + script(name)  # VMAD version 5, object format 2, one script


def vmad_mcm(name, quest_fid):
    v = struct.pack('<hhH', 5, 2, 1) + script(name)
    v += b'\x02' + struct.pack('<H', 0) + struct.pack('<H', 0)  # quest fragments: version 2, none, no file
    v += struct.pack('<H', 1)                                   # one alias script block
    v += struct.pack('<HhI', 0, 0, quest_fid)                   # alias 0 of this quest
    v += struct.pack('<hhH', 5, 2, 1) + script('SKI_PlayerLoadGameAlias')
    return v


def vmad_info_end_fragment(name):
    # one script with an end fragment, laid out like the vanilla marriage INFO's VMAD
    v = struct.pack('<hhH', 5, 2, 1) + script(name)
    v += b'\x02' + b'\x02' + wstr(name)            # fragment data v2, flags: on end, file name
    v += b'\x01' + wstr(name) + wstr('Fragment_0')
    return v


def ctda(op_flags, value, func, p1=0, p2=0, run_on=0):
    return sub(b'CTDA', struct.pack('<B3xfH2xIIIIi', op_flags, value, func, p1, p2, run_on, 0, -1))


EQ, GE = 0x00, 0x60
GetEquipped, GetInFaction, GetRelationshipRank = 182, 71, 403
AmuletOfMara, PlayerMarriedFaction = 0x0C891B, 0x0C6472

# start game enabled, run once off; priority 0 for the plain quests, 50 for the dialogue
DNAM = struct.pack('<HBBII', 0x0111, 0, 0xFF, 0, 0)
DNAM_DIALOGUE = struct.pack('<HBBII', 0x0111, 50, 0xFF, 0, 0)

BRIDGE, EVENTS, MCMQ, DIALOGUE = 0x01000800, 0x01000801, 0x01000802, 0x01000803
BRANCH, TOPIC, INFO = 0x01000804, 0x01000805, 0x01000806


def quest(fid, edid, full, vmad=None, alias=False, dnam=DNAM):
    d = sub(b'EDID', zstr(edid))
    if vmad:
        d += sub(b'VMAD', vmad)
    d += sub(b'FULL', zstr(full)) + sub(b'DNAM', dnam) + sub(b'NEXT', b'')
    if alias:
        d += sub(b'ANAM', struct.pack('<I', 1))
        d += sub(b'ALST', struct.pack('<I', 0)) + sub(b'ALID', zstr('PlayerAlias'))
        d += sub(b'FNAM', struct.pack('<I', 0)) + sub(b'ALFR', struct.pack('<I', 0x14))  # forced ref: the player
        d += sub(b'VTCK', struct.pack('<I', 0)) + sub(b'ALED', b'')
    else:
        d += sub(b'ANAM', struct.pack('<I', 0))
    return record(b'QUST', fid, d)


quests = quest(BRIDGE, 'COR_BridgeQuest', 'CHIM ORomance Bridge', vmad_plain('COR_Bridge'))
quests += quest(EVENTS, 'COR_EventsQuest', 'CHIM ORomance Bridge Events', vmad_plain('COR_Events'))
quests += quest(MCMQ, 'COR_MCMQuest', 'CHIM ORomance Bridge MCM', vmad_mcm('COR_MCM', MCMQ), alias=True)
quests += quest(DIALOGUE, 'COR_DialogueQuest', 'CHIM ORomance Bridge Dialogue', dnam=DNAM_DIALOGUE)

dial = record(b'DIAL', TOPIC,
              sub(b'EDID', zstr('COR_Propose')) + sub(b'FULL', zstr(PROMPT))
              + sub(b'PNAM', struct.pack('<f', 50.0)) + sub(b'BNAM', struct.pack('<I', BRANCH))
              + sub(b'QNAM', struct.pack('<I', DIALOGUE)) + sub(b'DATA', bytes(4))
              + sub(b'SNAM', b'CUST') + sub(b'TIFC', struct.pack('<I', 1)))

info = record(b'INFO', INFO,
              sub(b'VMAD', vmad_info_end_fragment('COR_TIF_Propose'))
              + sub(b'ENAM', struct.pack('<HH', 0x0001, 0))   # goodbye: the menu closes, then the fragment runs
              + sub(b'CNAM', b'\x00')
              + sub(b'TRDT', struct.pack('<IIIB3xIB3x', 5, 50, 0, 1, 0, 0))  # happy 50, response 1
              + sub(b'NAM1', zstr(REPLY)) + sub(b'NAM2', b'\x00') + sub(b'NAM3', b'\x00')
              + ctda(EQ, 1.0, GetEquipped, AmuletOfMara, run_on=1)         # on the player
              + ctda(GE, 1.0, GetRelationshipRank)                        # with the player: friend or more
              + ctda(EQ, 0.0, GetInFaction, PlayerMarriedFaction))        # not married to the player yet

dlbr = record(b'DLBR', BRANCH,
              sub(b'EDID', zstr('COR_ProposeBranch')) + sub(b'QNAM', struct.pack('<I', DIALOGUE))
              + sub(b'TNAM', struct.pack('<I', 0))   # category: player
              + sub(b'DNAM', struct.pack('<I', 1))   # top-level
              + sub(b'SNAM', struct.pack('<I', TOPIC)))

body = (group(b'DIAL', 0, dial + group(TOPIC, 7, info))
        + group(b'QUST', 0, quests)
        + group(b'DLBR', 0, dlbr))

hdr = sub(b'HEDR', struct.pack('<fII', 1.71, 11, 0x807))  # version 1.71, records + groups, next object id
hdr += sub(b'CNAM', zstr('SaurOff'))
hdr += sub(b'SNAM', zstr('CHIM ORomance Bridge - CHIM AI agents fall in love, marry and live as spouses through ORomance Plus.'))
hdr += sub(b'MAST', zstr('Skyrim.esm')) + sub(b'DATA', b'\0' * 8)
tes4 = b'TES4' + struct.pack('<IIIIHH', len(hdr), 0x200, 0, 0, 44, 0) + hdr

os.makedirs(os.path.dirname(SEQ), exist_ok=True)
open(OUT, 'wb').write(tes4 + body)
open(SEQ, 'wb').write(struct.pack('<I', DIALOGUE))
print("written", OUT, len(tes4 + body), "bytes and", SEQ)
