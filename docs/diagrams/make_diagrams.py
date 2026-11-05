"""Generates CampusFix's draw.io diagrams (standard UML / ER notation)."""
import os
import sys
from xml.sax.saxutils import quoteattr

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

FONT = 'fontFamily=Helvetica;fontSize=12;'


class Diagram:
    def __init__(self, name, w, h):
        self.name, self.w, self.h = name, w, h
        self.cells = []
        self.n = 2

    def _id(self):
        i = f'c{self.n}'
        self.n += 1
        return i

    def v(self, label, x, y, w, h, style, parent='1'):
        i = self._id()
        self.cells.append(
            f'<mxCell id="{i}" value={quoteattr(label)} style={quoteattr(FONT + style)} '
            f'vertex="1" parent="{parent}"><mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" '
            f'as="geometry"/></mxCell>')
        return i

    def e(self, label='', src=None, tgt=None, style='', pts=None, sp=None, tp=None, rel=False):
        i = self._id()
        a = f' source="{src}"' if src else ''
        a += f' target="{tgt}"' if tgt else ''
        geo = ''
        if sp:
            geo += f'<mxPoint x="{sp[0]}" y="{sp[1]}" as="sourcePoint"/>'
        if tp:
            geo += f'<mxPoint x="{tp[0]}" y="{tp[1]}" as="targetPoint"/>'
        if pts:
            geo += '<Array as="points">' + ''.join(
                f'<mxPoint x="{x}" y="{y}"/>' for x, y in pts) + '</Array>'
        self.cells.append(
            f'<mxCell id="{i}" value={quoteattr(label)} style={quoteattr(FONT + "html=1;" + style)} '
            f'edge="1" parent="1"{a}><mxGeometry relative="1" as="geometry">{geo}</mxGeometry></mxCell>')
        return i

    def save(self, file):
        body = ''.join(self.cells)
        xml = (f'<mxfile host="CampusFix"><diagram name={quoteattr(self.name)} id="{file}">'
               f'<mxGraphModel dx="{self.w}" dy="{self.h}" grid="1" gridSize="10" guides="1" '
               f'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
               f'pageWidth="{self.w}" pageHeight="{self.h}" math="0" shadow="0"><root>'
               f'<mxCell id="0"/><mxCell id="1" parent="0"/>{body}</root></mxGraphModel>'
               f'</diagram></mxfile>')
        with open(os.path.join(OUT, file + '.drawio'), 'w', encoding='utf8') as f:
            f.write(xml)


GREEN = 'fillColor=#E8F5EC;strokeColor=#15803D;'
GREY = 'fillColor=#F5F5F5;strokeColor=#666666;'
BLUE = 'fillColor=#EAF0FB;strokeColor=#234A8F;'
ORANGE = 'fillColor=#FFF2DB;strokeColor=#8A5300;'
WHITE = 'fillColor=#FFFFFF;strokeColor=#333333;'

# ---------------------------------------------------------------- 1. use cases
d = Diagram('Use case diagram', 1000, 760)
d.v('CampusFix', 190, 20, 620, 700,
    'rounded=0;whiteSpace=wrap;html=1;verticalAlign=top;fontStyle=1;fontSize=14;' + WHITE)
actor = 'shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;'
student = d.v('Student', 70, 260, 30, 60, actor)
staff = d.v('Staff', 890, 230, 30, 60, actor)
admin = d.v('Admin<br>(Firebase Console)', 890, 560, 30, 60, actor)
uc = 'ellipse;whiteSpace=wrap;html=1;' + WHITE
L, M, R, W, H = 210, 405, 600, 185, 56
u_reg = d.v('Register with<br>ALU email', L, 60, W, H, uc)
u_ver = d.v('Verify email', L, 140, W, H, uc)
u_sub = d.v('Submit incident report', L, 300, W, H, uc)
u_pho = d.v('Attach photo', L, 400, W, H, uc)
u_cat = d.v('Choose category<br>and building', L, 500, W, H, uc)
u_edit = d.v('Edit or delete own report<br>(while Submitted)', L, 600, W, H + 4, uc)
u_in = d.v('Sign in / sign out', M, 60, W, H, uc)
u_pw = d.v('Reset password', M, 140, W, H, uc)
u_brw = d.v('Browse, search and<br>filter reports', M, 240, W, H, uc)
u_det = d.v('View report details<br>and status timeline', M, 330, W, H, uc)
u_not = d.v('View notifications', M, 420, W, H, uc)
u_dash = d.v('View staff dashboard', R, 140, W, H, uc)
u_upd = d.v('Update report status', R, 300, W, H, uc)
u_ntf = d.v('Notify reporter', R, 400, W, H, uc)
u_rsn = d.v('Give reason<br>for rejection', R, 490, W, H, uc)
u_mk = d.v('Create staff account /<br>assign staff role', R, 600, W, H, uc)
assoc = 'endArrow=none;'
for t in (u_reg, u_ver, u_sub, u_edit, u_in, u_pw, u_brw, u_det, u_not):
    d.e('', student, t, assoc)
for t in (u_in, u_pw, u_brw, u_det, u_dash, u_upd):
    d.e('', staff, t, assoc)
d.e('', admin, u_mk, assoc)
dep = 'dashed=1;endArrow=open;endFill=0;'
d.e('«extend»', u_pho, u_sub, dep)
d.e('«include»', u_sub, u_cat, dep + 'exitX=0.3;exitY=1;entryX=0.3;entryY=0;')
d.e('«include»', u_upd, u_ntf, dep)
d.e('«extend»<br>[status = Rejected]', u_rsn, u_ntf, dep + 'exitX=1;exitY=0.5;entryX=1;entryY=0.5;',
    pts=[(800, 518), (800, 428)])
d.save('01-use-case')

# ---------------------------------------------------------------- 2. architecture
d = Diagram('Layered architecture', 960, 760)
lane = 'swimlane;html=1;startSize=28;horizontal=1;whiteSpace=wrap;rounded=1;arcSize=4;'
comp = 'rounded=1;whiteSpace=wrap;html=1;arcSize=8;'
app = d.v('CampusFix Flutter app (Android)', 20, 20, 920, 500,
          lane + 'fontStyle=1;fontSize=14;fillColor=#FAFAFA;strokeColor=#333333;')


def layer(title, y, items, colour):
    lay = d.v(title, 20, y, 880, 104, lane + 'fontStyle=1;' + colour, parent=app)
    ids = []
    for i, label in enumerate(items):
        ids.append(d.v(label, 16 + i * 172, 38, 160, 54, comp + WHITE, parent=lay))
    return lay, ids


pres, (p_auth, p_shell, p_stu, p_staff, p_wid) = layer(
    'Presentation layer: screens and widgets (lib/screens, lib/widgets)', 40, [
        '<b>AuthGate</b><br>auth screens', '<b>AppShell</b><br>role-based tabs',
        '<b>Student screens</b><br>Home, Reports, Details, Form',
        '<b>Staff screens</b><br>Dashboard, Status update', '<b>Shared widgets</b><br>cards, fields, pills'],
    BLUE)
state, (s_auth, s_inc, s_not, s_sh, s_flt) = layer(
    'State layer: Provider / ChangeNotifier (lib/providers)', 164, [
        '<b>AuthProvider</b><br>session, profile, role', '<b>IncidentProvider</b><br>live list, filter, saving',
        '<b>NotificationProvider</b><br>inbox, unread count', '<b>ShellProvider</b><br>selected tab',
        '<b>IncidentFilter</b><br>immutable filter'], GREEN)
data, (r_auth, r_inc, r_not, r_sto, r_mod) = layer(
    'Data layer: services and models (lib/services, lib/models)', 288, [
        '<b>AuthService</b>', '<b>IncidentRepository</b>', '<b>NotificationRepository</b>',
        '<b>StorageService</b>', '<b>Models</b><br>AppUser, Incident, AppNotification'], ORANGE)
d.v('<b>core</b>: theme (Figtree, colours), constants (categories, statuses, buildings), '
    'validators, formatters, Phosphor icons', 20, 416, 880, 56, comp + GREY, parent=app)
fb = d.v('Google Firebase', 20, 560, 560, 170, lane + 'fontStyle=1;' + 'fillColor=#FFF8E1;strokeColor=#F57C00;')
x_auth = d.v('<b>Firebase<br>Authentication</b>', 20, 50, 160, 64, comp + WHITE, parent=fb)
x_fs = d.v('<b>Cloud Firestore</b><br>users, incidents,<br>notifications', 200, 50, 160, 64, comp + WHITE, parent=fb)
x_rules = d.v('<b>Security Rules</b><br>firestore.rules', 380, 50, 160, 64, comp + WHITE, parent=fb)
cf = d.v('Cloudflare (free tier)', 600, 560, 340, 170, lane + 'fontStyle=1;fillColor=#FFF3E0;strokeColor=#E65100;')
x_wk = d.v('<b>Photo Worker</b><br>photo-worker.js', 20, 50, 140, 64, comp + WHITE, parent=cf)
x_kv = d.v('<b>Workers KV</b><br>photo files', 180, 50, 140, 64, comp + WHITE, parent=cf)
x_jw = d.v('<b>Google public keys</b> (JWKS) for ID tokens', 20, 128, 300, 30, comp + GREY, parent=cf)
use = 'dashed=1;endArrow=open;endFill=0;'
d.e('context.watch / select<br>calls actions', pres, state, use)
d.e('calls methods,<br>listens to streams', state, data, use)
call = 'endArrow=block;endFill=1;edgeStyle=orthogonalEdgeStyle;'
d.e('sign-in, sign-up,<br>verification', r_auth, x_auth, call)
d.e('snapshots,<br>batched writes', r_inc, x_fs, call)
d.e('', r_not, x_fs, call)
d.e('HTTPS + Firebase<br>ID token', r_sto, x_wk, call)
d.e('put / get / delete', x_wk, x_kv, call)
d.e('verify RS256', x_wk, x_jw, call + 'exitX=0.5;exitY=1;entryX=0.25;entryY=0;')
d.e('guards every<br>request', x_rules, x_fs, 'dashed=1;endArrow=open;')
d.save('02-architecture')

# ---------------------------------------------------------------- 3. ER diagram
d = Diagram('Entity relationship diagram', 1100, 760)
ent = ('swimlane;fontStyle=1;childLayout=stackLayout;horizontal=1;startSize=30;horizontalStack=0;'
       'resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=0;marginBottom=0;html=1;rounded=1;arcSize=4;')
row = ('text;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;spacingLeft=8;'
       'spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;html=1;')


def entity(title, x, y, w, rows, colour):
    e = d.v(title, x, y, w, 30 + 26 * len(rows), ent + colour)
    for i, r in enumerate(rows):
        d.v(r, 0, 30 + 26 * i, w, 26, row, parent=e)
    return e


users = entity('users  (Firestore collection)', 40, 60, 270, [
    '<b>PK</b>  uid : string  (Firebase Auth UID)', 'name : string', 'email : string',
    "role : 'student' | 'staff'", 'department : string?', 'createdAt : timestamp'], BLUE)
inc = entity('incidents  (Firestore collection)', 400, 60, 310, [
    '<b>PK</b>  id : string  (auto)', 'reference : string  (CF-XXXXXX)', 'title : string  (5 to 80)',
    'description : string  (15 to 1000)', 'category : enum (6 values)', 'location : string  (building)',
    'locationDetail : string  (exact spot)', 'status : enum (4 values)', '<b>FK</b>  reporterId : string',
    'reporterName : string', 'photoUrl : string?', 'photoPath : string?', 'history : StatusChange[]',
    'createdAt : timestamp', 'updatedAt : timestamp'], GREEN)
notif = entity('notifications  (Firestore collection)', 790, 60, 280, [
    '<b>PK</b>  id : string  (auto)', '<b>FK</b>  userId : string', '<b>FK</b>  incidentId : string',
    'title : string', 'body : string', 'status : enum', 'read : boolean', 'createdAt : timestamp'], BLUE)
hist = entity('StatusChange  (embedded in history[])', 400, 560, 310, [
    'status : enum', 'at : timestamp', 'byName : string', 'note : string?'], ORANGE)
photo = entity('Photo object  (Cloudflare Workers KV)', 40, 560, 300, [
    '<b>PK</b>  key : incidents/{uid}/{id}_{ts}.jpg', 'value : JPEG bytes  (max 5 MB)',
    'metadata.contentType : image/*'], GREY)
er = 'edgeStyle=entityRelationEdgeStyle;fontSize=11;'
d.e('files (reporterId)', users, inc, er + 'startArrow=ERmandOne;endArrow=ERzeroToMany;'
    'exitX=1;exitY=0.25;entryX=0;entryY=0.6;')
d.e('receives (userId)', users, notif, 'edgeStyle=orthogonalEdgeStyle;fontSize=11;startArrow=ERmandOne;'
    'endArrow=ERzeroToMany;exitX=0.5;exitY=0;entryX=0.5;entryY=0;', pts=[(175, 30), (930, 30)])
d.e('triggers (incidentId)', inc, notif, er + 'startArrow=ERmandOne;endArrow=ERzeroToMany;'
    'exitX=1;exitY=0.2;entryX=0;entryY=0.4;')
d.e('records (embedded)', inc, hist, 'edgeStyle=orthogonalEdgeStyle;fontSize=11;startArrow=ERmandOne;'
    'endArrow=ERoneToMany;exitX=0.5;exitY=1;entryX=0.5;entryY=0;')
d.e('has (photoPath)', inc, photo, 'edgeStyle=orthogonalEdgeStyle;fontSize=11;startArrow=ERmandOne;'
    'endArrow=ERzeroToOne;exitX=0;exitY=0.75;entryX=0.5;entryY=0;', pts=[(190, 400)])
d.save('03-er-diagram')

# ---------------------------------------------------------------- sequence helpers
LIFE = ('shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;html=1;container=1;'
        'collapsible=0;recursiveResize=0;outlineConnect=0;size=44;')
ACT = LIFE + 'participant=umlActor;verticalAlign=top;spacingTop=40;'
ACTV = 'html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;' + WHITE
SYNC = 'verticalAlign=bottom;endArrow=block;endFill=1;fontSize=11;'
ASYNC = 'verticalAlign=bottom;endArrow=open;endFill=0;fontSize=11;'
RET = 'verticalAlign=bottom;endArrow=open;endFill=0;dashed=1;fontSize=11;'
FRAME = 'shape=umlFrame;whiteSpace=wrap;html=1;pointerEvents=0;width=70;height=24;fontStyle=1;'


def lifelines(d, names, x0, gap, height, actors=()):
    cx = {}
    for i, n in enumerate(names):
        x = x0 + i * gap
        if n in actors:
            d.v(n, x - 20, 20, 40, height, ACT)
        else:
            d.v(n, x - 65, 20, 130, height, LIFE + WHITE)
        cx[n] = x
    return cx


def msg(d, cx, a, b, y, label, style=SYNC):
    off = 5 if cx[b] > cx[a] else -5
    d.e(label, style=style, sp=(cx[a] + off, y), tp=(cx[b] - off, y))


def self_msg(d, cx, a, y, label):
    x = cx[a] + 5
    d.e(label, style=SYNC + 'align=left;spacingLeft=6;', sp=(x, y), tp=(x, y + 22),
        pts=[(x + 36, y), (x + 36, y + 22)])


def bar(d, cx, a, y1, y2):
    d.v('', cx[a] - 5, y1, 10, y2 - y1, ACTV)


# ---------------------------------------------------------------- 4. sequence: submit
d = Diagram('Sequence: submit a report', 1340, 760)
P = ['Student', ':ReportFormScreen', ':IncidentProvider', ':IncidentRepository', ':StorageService',
     ':PhotoWorker', ':WorkersKV', ':CloudFirestore']
cx = lifelines(d, P, 70, 170, 720, actors=('Student',))
for a, y1, y2 in [(':ReportFormScreen', 96, 680), (':IncidentProvider', 176, 640),
                  (':IncidentRepository', 206, 610), (':StorageService', 256, 470),
                  (':PhotoWorker', 286, 440), (':WorkersKV', 386, 412), (':CloudFirestore', 506, 590)]:
    bar(d, cx, a, y1, y2)
msg(d, cx, 'Student', ':ReportFormScreen', 100, 'tap Send report')
self_msg(d, cx, ':ReportFormScreen', 120, 'validate() all fields')
msg(d, cx, ':ReportFormScreen', ':IncidentProvider', 180, 'submit(draft, photo)')
msg(d, cx, ':IncidentProvider', ':IncidentRepository', 210, 'create(draft, photo)')
d.v('opt', cx[':IncidentRepository'] - 30, 232, 620, 250, FRAME + 'fillColor=none;')
d.v('[photo attached]', cx[':IncidentRepository'] + 45, 234, 120, 20, 'text;html=1;fontSize=11;')
msg(d, cx, ':IncidentRepository', ':StorageService', 260, 'uploadPhoto(file)')
msg(d, cx, ':StorageService', ':PhotoWorker', 290, 'POST photo + ID token')
self_msg(d, cx, ':PhotoWorker', 310, 'verify token: signature, aud,<br>iss, exp, email_verified, owner')
msg(d, cx, ':PhotoWorker', ':WorkersKV', 390, 'put(key, bytes)')
msg(d, cx, ':WorkersKV', ':PhotoWorker', 410, 'stored', RET)
msg(d, cx, ':PhotoWorker', ':StorageService', 440, '201 {url, path}', RET)
msg(d, cx, ':StorageService', ':IncidentRepository', 468, '(url, path)', RET)
msg(d, cx, ':IncidentRepository', ':CloudFirestore', 510,
    'batch.commit(): incident + "Report received" notification')
self_msg(d, cx, ':CloudFirestore', 530, 'security rules:<br>verified(), validDetails()')
msg(d, cx, ':CloudFirestore', ':IncidentRepository', 588, 'committed', RET)
msg(d, cx, ':IncidentRepository', ':IncidentProvider', 608, 'Incident', RET)
msg(d, cx, ':IncidentProvider', ':ReportFormScreen', 638, 'success', RET)
msg(d, cx, ':ReportFormScreen', 'Student', 678, 'Report sent (CF-XXXXXX)', RET)
d.save('04-sequence-submit-report')

# ---------------------------------------------------------------- 5. sequence: status update
d = Diagram('Sequence: staff updates a status', 1340, 760)
P = ['Staff', ':StaffUpdateScreen', ':IncidentProvider', ':IncidentRepository', ':CloudFirestore',
     'student :IncidentProvider', 'student :NotificationProvider', 'Student']
cx = lifelines(d, P, 70, 170, 720, actors=('Staff', 'Student'))
for a, y1, y2 in [(':StaffUpdateScreen', 96, 430), (':IncidentProvider', 186, 400),
                  (':IncidentRepository', 256, 380), (':CloudFirestore', 286, 360),
                  ('student :IncidentProvider', 506, 560), ('student :NotificationProvider', 596, 650)]:
    bar(d, cx, a, y1, y2)
msg(d, cx, 'Staff', ':StaffUpdateScreen', 100, 'choose status, tap Update')
self_msg(d, cx, ':StaffUpdateScreen', 120, 'validate: Rejected<br>needs a reason')
msg(d, cx, ':StaffUpdateScreen', ':IncidentProvider', 190, 'updateStatus(status, note)')
self_msg(d, cx, ':IncidentProvider', 210, 'check role == staff')
msg(d, cx, ':IncidentProvider', ':IncidentRepository', 260, 'updateStatus(...)')
msg(d, cx, ':IncidentRepository', ':CloudFirestore', 290,
    'batch: status, history,<br>notification')
self_msg(d, cx, ':CloudFirestore', 310, 'rules: isStaff(), changedOnly,<br>history grows by exactly 1')
msg(d, cx, ':CloudFirestore', ':IncidentRepository', 358, 'committed', RET)
msg(d, cx, ':IncidentRepository', ':IncidentProvider', 378, 'done', RET)
msg(d, cx, ':IncidentProvider', ':StaffUpdateScreen', 398, 'done', RET)
msg(d, cx, ':StaffUpdateScreen', 'Staff', 428, 'Status updated', RET)
d.v('par', cx[':CloudFirestore'] - 30, 470, 560, 210, FRAME + 'fillColor=none;')
d.v('[real-time listeners on the student\'s phone]', cx[':CloudFirestore'] + 45, 472, 280, 20,
    'text;html=1;fontSize=11;')
msg(d, cx, ':CloudFirestore', 'student :IncidentProvider', 510, 'incidents snapshot', ASYNC)
msg(d, cx, 'student :IncidentProvider', 'Student', 556,
    'Home, Reports and timeline update', RET)
d.e('', style='dashed=1;endArrow=none;strokeColor=#999999;', sp=(cx[':CloudFirestore'] - 30, 576),
    tp=(cx[':CloudFirestore'] + 530, 576))
msg(d, cx, ':CloudFirestore', 'student :NotificationProvider', 600, 'notifications snapshot', ASYNC)
msg(d, cx, 'student :NotificationProvider', 'Student', 646, 'unread badge on the bell', RET)
d.save('05-sequence-status-update')

# ---------------------------------------------------------------- 6. state machine
d = Diagram('State machine: report status', 1000, 560)
st = 'rounded=1;whiteSpace=wrap;html=1;arcSize=30;verticalAlign=top;spacingTop=6;'
init = d.v('', 40, 140, 30, 30, 'ellipse;html=1;fillColor=#000000;strokeColor=#000000;')
s_sub = d.v('<b>Submitted</b><hr>entry / add history entry,<br>notify reporter<br>reporter may edit or delete',
            130, 100, 200, 110, st + BLUE)
s_prog = d.v('<b>In progress</b><hr>entry / add history entry,<br>notify reporter', 440, 100, 200, 110, st + ORANGE)
s_res = d.v('<b>Resolved</b><hr>entry / add history entry,<br>notify reporter', 760, 100, 200, 110, st + GREEN)
s_rej = d.v('<b>Rejected</b><hr>entry / add history entry<br>with reason, notify reporter',
            440, 340, 200, 110, st + 'fillColor=#FCE8E6;strokeColor=#A1281C;')
fin = d.v('', 215, 420, 30, 30, 'ellipse;html=1;shape=endState;fillColor=#000000;strokeColor=#000000;')
tr = 'endArrow=open;endFill=0;fontSize=11;edgeStyle=orthogonalEdgeStyle;'
d.e('submit [verified ALU student]', init, s_sub, tr)
d.e('edit details<br>[reporter]', s_sub, s_sub, tr + 'exitX=0.25;exitY=0;entryX=0.75;entryY=0;',
    pts=[(180, 60), (280, 60)])
d.e('delete [reporter]', s_sub, fin, tr + 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;')
d.e('updateStatus [staff]', s_sub, s_prog, tr)
d.e('updateStatus [staff]', s_prog, s_res, tr)
d.e('updateStatus [staff,<br>reason given]', s_sub, s_rej, tr + 'exitX=0.75;exitY=1;entryX=0;entryY=0.5;',
    pts=[(280, 395)])
d.e('updateStatus [staff,<br>reason given]', s_prog, s_rej, tr + 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;')
d.e('reopen: updateStatus [staff]', s_res, s_prog, tr + 'exitX=0.5;exitY=1;entryX=0.75;entryY=1;',
    pts=[(860, 260), (590, 260)])
d.save('06-state-machine-status')

# ---------------------------------------------------------------- 7. activity: auth
d = Diagram('Activity: authentication and access', 1000, 1120)
act = 'rounded=1;whiteSpace=wrap;html=1;arcSize=40;' + WHITE
dec = 'rhombus;whiteSpace=wrap;html=1;' + WHITE
flow = 'endArrow=open;endFill=0;fontSize=11;edgeStyle=orthogonalEdgeStyle;'
a0 = d.v('', 425, 20, 30, 30, 'ellipse;html=1;fillColor=#000000;strokeColor=#000000;')
q_acc = d.v('Has an<br>account?', 380, 80, 120, 80, dec)
# left column: register
r1 = d.v('Register: name, email, password', 60, 190, 240, 50, act)
q_alu1 = d.v('ALU email?', 120, 270, 120, 80, dec)
r_err = d.v('Show "Use your ALU email"', 60, 380, 240, 44, act + 'fillColor=#FCE8E6;strokeColor=#A1281C;')
r2 = d.v('Create Auth user, send verification email,<br>create users/{uid} with role = student',
         40, 460, 280, 60, act)
# right column: sign in
s1 = d.v('Sign in: email, password', 580, 190, 240, 50, act)
q_cred = d.v('Credentials<br>valid?', 640, 270, 120, 80, dec)
s_err = d.v('Show "Email or password<br>is incorrect"', 840, 280, 150, 60, act + 'fillColor=#FCE8E6;strokeColor=#A1281C;')
q_alu2 = d.v('ALU email?', 640, 380, 120, 80, dec)
q_stf = d.v('users/{uid}.role<br>== staff?', 820, 380, 140, 80, dec)
s_out = d.v('Sign out, show "CampusFix<br>is for ALU accounts"', 815, 500, 150, 60,
            act + 'fillColor=#FCE8E6;strokeColor=#A1281C;')
e_out = d.v('', 875, 600, 30, 30, 'ellipse;html=1;shape=endState;fillColor=#000000;strokeColor=#000000;')
# shared: verification and role
mrg = d.v('', 425, 560, 30, 30, 'rhombus;html=1;' + WHITE)
q_ver = d.v('Email<br>verified?', 380, 630, 120, 80, dec)
v1 = d.v('Verify email screen: resend link,<br>tap "I\'ve verified"', 40, 640, 260, 60, act)
p1 = d.v('Load users/{uid} profile<br>(create it if missing)', 330, 750, 220, 56, act)
q_role = d.v('role?', 380, 840, 120, 80, dec)
t1 = d.v('Student shell:<br>Home, Reports, Profile', 150, 960, 200, 56, act + BLUE)
t2 = d.v('Staff shell: Dashboard,<br>All reports, Profile', 530, 960, 200, 56, act + GREEN)
e_end = d.v('', 425, 1060, 30, 30, 'ellipse;html=1;shape=endState;fillColor=#000000;strokeColor=#000000;')
d.e('', a0, q_acc, flow)
d.e('[no]', q_acc, r1, flow + 'exitX=0;exitY=0.5;')
d.e('[yes]', q_acc, s1, flow + 'exitX=1;exitY=0.5;')
d.e('', r1, q_alu1, flow)
d.e('[no]', q_alu1, r_err, flow)
d.e('', r_err, r1, flow + 'exitX=0;exitY=0.5;entryX=0;entryY=0.5;', pts=[(30, 402), (30, 215)])
d.e('[yes]', q_alu1, r2, flow + 'exitX=1;exitY=0.5;entryX=0.5;entryY=0;', pts=[(330, 310), (330, 440), (180, 440)])
d.e('', r2, mrg, flow + 'exitX=0.5;exitY=1;entryX=0;entryY=0.5;', pts=[(180, 575)])
d.e('', s1, q_cred, flow)
d.e('[no]', q_cred, s_err, flow)
d.e('', s_err, s1, flow + 'exitX=0.5;exitY=0;entryX=1;entryY=0.5;', pts=[(915, 215)])
d.e('[yes]', q_cred, q_alu2, flow)
d.e('[no]', q_alu2, q_stf, flow)
d.e('[no]', q_stf, s_out, flow)
d.e('', s_out, e_out, flow)
d.e('[yes]', q_alu2, mrg, flow + 'exitX=0.5;exitY=1;entryX=1;entryY=0.5;', pts=[(700, 575)])
d.e('[yes]', q_stf, mrg, flow + 'exitX=0;exitY=1;entryX=0.5;entryY=0;', pts=[(780, 480), (780, 530), (440, 530)])
d.e('', mrg, q_ver, flow)
d.e('[no]', q_ver, v1, flow)
d.e('link opened', v1, q_ver, flow + 'exitX=0.5;exitY=1;entryX=0.5;entryY=1;', pts=[(170, 730), (440, 730)])
d.e('[yes]', q_ver, p1, flow + 'exitX=1;exitY=0.5;entryX=1;entryY=0.5;', pts=[(580, 670), (580, 778)])
d.e('', p1, q_role, flow)
d.e('[student]', q_role, t1, flow + 'exitX=0;exitY=0.5;')
d.e('[staff]', q_role, t2, flow + 'exitX=1;exitY=0.5;')
d.e('', t1, e_end, flow + 'exitX=0.5;exitY=1;entryX=0;entryY=0.5;', pts=[(250, 1075)])
d.e('', t2, e_end, flow + 'exitX=0.5;exitY=1;entryX=1;entryY=0.5;', pts=[(630, 1075)])
d.save('07-activity-authentication')
print('written to', OUT)
