%read binary data given cmm_type t and cmm_dim s from fid 
%for lists read nr entries and skip ns entries
function data = cmm_read_data(fid, t, s, nr, ns)
   if nargin <4
      nr=-1;
      ns=0;
   elseif nargin<5
      ns = nr;
      nr = 1;
   end
   
   c = from_cmm_type(t);  
   if isempty(s) % scalar
      if strcmp(t, 'T')
         data = cmm_fread_str(fid);
      elseif strcmp(t, 'B')
         data = cmm_fread_bool(fid);
      else
         data = fread(fid, 1, [c '=>' c]);
      end
      return

   else %array
      if strcmp(t, 'T')
         if (nr<0)
            data = cmm_fread_str_list(fid, prod(s));
         else
            data = cmm_fread_str_list_skip(fid,s,nr,ns);
            s(1) = numel(data)/prod(s(2:end));
         end
      elseif strcmp(t, 'B')
         if (nr<0)
            data = cmm_fread_bool_list(fid, prod(s));
         else
            data = cmm_fread_bool_list_skip(fid,s,nr,ns);
            s(1) = numel(data)/prod(s(2:end));
         end
      else
         if s(1)<0         % continuous stream of data
            pos = ftell(fid);
            fseek(fid, 0, 'eof');
            b = sizeof_cmm_type(t);
            s(1) = (ftell(fid) - pos)/b/prod(s(2:end));
            fseek(fid, pos, 'bof')
         end

         if (nr<0)
            data = fread(fid, prod(s), [c '=>' c]);
         else
            data = cmm_fread_skip(fid, t, s, nr, ns);
            s(1) = numel(data)/prod(s(2:end));
         end
      end
   end
   data = cmm_reshape(data, s);
end

% skipping 

%reading nr sub arrays and skipping ns ones
function data = cmm_fread_skip(fid, t, s, nr, ns)
   c = from_cmm_type(t);
   n = floor(s(1)/(nr+ns));
   if (mod(s(1),nr+ns)>=nr)
      n=n+1;
   end
   bs = sizeof_cmm_type(t) * prod(s(2:end))*ns;   
   p = prod(s(2:end))*nr;
   data = zeros(1, p*n, c);
   for k=1:n
      data((k-1)*p+1 : k*p)=fread(fid, p, [c '=>' c]);
      fseek(fid, bs, 'cof');
   end
end



% specializations for strings

%read null terminated string
function data = cmm_fread_str(fid)
   c = fread(fid, 1, 'uint8=>char');
   data = [];
   while strcmp(c, char(0))==0 && ~feof(fid)
      data = [data c];
      c = fread(fid, 1, 'uint8=>char');
   end
end

%read list of null terminated string
function data = cmm_fread_str_list(fid, size)
   if (size < 0 || size == inf)
      data= {};
      k=1;
      while feof(fid)==0
         data{k} = cmm_fread_str(fid);
         k=k+1;
      end
   else
      data = cell(1,size);
      for k=1:size
         data{k} = cmm_fread_str(fid);
      end
   end
end

%read list of null terminated string skip
function data = cmm_fread_str_list_skip(fid, s, nr, ns)
   if (s(1) < 0)
      data= {};
      k=1;
      data = cell(1,1);
      while feof(fid)==0
         data{k:k+nr-1} = cmm_fread_str_list(fid, nr);
         k=k+nr;
         if feof(fid)==1; return; end
         cmm_fread_str_list(fid, ns);
      end
   else 
      n = floor(s(1)/(nr+ns));
      if (mod(s(1),nr+ns)>=nr)
         n=n+1;
      end  
      p = prod(s(2:end))*nr;     
      b = prod(s(2:end))*ns;
      data = cell(1,p*n);
      for k=1:n
         data((k-1)*p+1:k*p) = cmm_fread_str_list(fid, p);
         cmm_fread_str_list(fid, b);
      end
   end
end


%read bool
function data = cmm_fread_bool(fid)
   c = fread(fid, 1, 'uint8=>char');
   if (c == 't') 
      data = true;
   else
      data = false;
   end
end


%read list of bools
function data = cmm_fread_bool_list(fid, size)
   if (size < 0 || size == inf)
      data= [];
      k=1;
      while feof(fid)==0
         data(k) = cmm_fread_bool(fid);
         k=k+1;
      end
   else
      data = [];
      for k=1:size
         data(k) = cmm_fread_bool(fid);
      end
   end
end


%read list of bools skip 
function data = cmm_fread_bool_list_skip(fid, s, nr, ns)
   if (s(1) < 0)
      data=[];
      k=1;
      while feof(fid)==0
         data(k:k+nr-1) = cmm_fread_bool_list(fid, nr);
         k=k+nr;
         if feof(fid)==1; return; end
         cmm_fread_bool_list(fid, ns);
      end
   else 
      n = floor(s(1)/(nr+ns));
      if (mod(s(1),nr+ns)>=nr)
         n=n+1;
      end  
      p = prod(s(2:end))*nr;     
      b = prod(s(2:end))*ns;
      data = [];
      for k=1:n
         data((k-1)*p+1:k*p) = cmm_fread_bool_list(fid, p);
         cmm_fread_bool_list(fid, b);
      end
   end
end
