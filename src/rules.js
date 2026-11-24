export const transitions={pending:['confirmed','cancelled'],confirmed:['preparing','cancelled'],preparing:['ready'],ready:['waiting','on_way'],waiting:['delivered'],on_way:['delivered'],delivered:[],cancelled:[]};
export function canTransition(from,to,method){return transitions[from]?.includes(to)&&!(to==='waiting'&&method!=='pickup')&&!(to==='on_way'&&method!=='delivery')}
export const hashableItems=items=>[...items].sort((a,b)=>a.id.localeCompare(b.id));
export const isUUID=v=>typeof v==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
export const validItems=items=>Array.isArray(items)&&items.length>0&&items.length<=100&&items.every(x=>x&&typeof x.id==='string'&&/^[a-z0-9-]{1,80}$/.test(x.id)&&Number.isInteger(x.quantity)&&x.quantity>0&&x.quantity<=99)&&new Set(items.map(x=>x.id)).size===items.length;
