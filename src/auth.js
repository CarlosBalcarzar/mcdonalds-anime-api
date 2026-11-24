import {randomBytes,scryptSync,timingSafeEqual,createHash} from 'node:crypto';
import {query,tx} from './db.js';
export const digest=s=>createHash('sha256').update(s).digest('hex');
export function passwordHash(p){const salt=randomBytes(16).toString('hex');return salt+':'+scryptSync(p,salt,64).toString('hex')}
export function matches(p,h){if(!h)return false;const [salt,key]=h.split(':');return timingSafeEqual(scryptSync(p,salt,64),Buffer.from(key,'hex'))}
export const external=Boolean(process.env.SUPABASE_URL&&process.env.SUPABASE_PUBLISHABLE_KEY);
export function fail(status,message){throw Object.assign(new Error(message),{status})}
export async function session(user){const token=randomBytes(32).toString('hex');await query('INSERT INTO sessions VALUES($1,$2,now()+interval \'12 hours\')',[digest(token),user.id]);return token}
export async function identity(req,res,next){try{const token=req.get('authorization')?.match(/^Bearer (\S+)$/)?.[1];if(!token)return next();let rows;if(external){const response=await fetch(process.env.SUPABASE_URL+'/auth/v1/user',{headers:{apikey:process.env.SUPABASE_PUBLISHABLE_KEY,Authorization:'Bearer '+token},signal:AbortSignal.timeout(10000)});if(!response.ok)fail(401,'Sesión inválida');const u=await response.json();if(!u.email||!u.id)fail(401,'Identidad no válida');await query('INSERT INTO profiles(id,name,email) VALUES($1,$2,$3) ON CONFLICT(id) DO NOTHING',[u.id,u.user_metadata?.name||u.email,u.email.toLowerCase()]);({rows}=await query('SELECT id,name,email,role,active FROM profiles WHERE id=$1',[u.id]));}else{({rows}=await query('SELECT p.id,p.name,p.email,p.role,p.active FROM sessions s JOIN profiles p ON p.id=s.user_id WHERE token_hash=$1 AND expires_at>now()',[digest(token)]));}if(!rows[0]?.active)fail(401,'Sesión inválida o cuenta inactiva');req.user=rows[0];req.token=token;next()}catch(e){next(e)}}
export function requireUser(req,res,next){if(!req.user)return next(Object.assign(new Error('Inicia sesión'),{status:401}));next()}
export const has=async(u,p,c={query})=>Boolean(u&&(await c.query('SELECT 1 FROM role_permissions WHERE role=$1 AND permission=$2',[u.role,p])).rowCount);
export const need=p=>async(req,res,next)=>{try{if(!await has(req.user,p))fail(req.user?403:401,'Acceso no autorizado');next()}catch(e){next(e)}};
