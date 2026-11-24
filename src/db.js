import {connection} from './connection.js';
import pg from 'pg';
export const pool=new pg.Pool({...connection(process.env.DATABASE_URL||process.env.MIGRATION_DATABASE_URL),options:'-c search_path=mcd,public'});
export const query=(s,p=[])=>pool.query(s,p);
export async function tx(fn){const c=await pool.connect();try{await c.query('BEGIN');const value=await fn(c);await c.query('COMMIT');return value}catch(e){await c.query('ROLLBACK');throw e}finally{c.release()}}
