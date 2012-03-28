% flatten data appropiately and write to binary file f for use with
% c++ via cmmfile.h or Mathematica via CMMFile.m
% note: list of strings is assumed to be cell of strings
% note: for dimension treatment see cmm_read_data

function cmm_write_data(fid, data, t, s)
   if nargin<4
      s = cmm_dim(data);
   end

   if ischarcell(data)
      data = to_cmm_shape(data, s);
      cmm_fwrite_str_list(fid, data);
      return
   end
   
   if nargin<3
      t = cmm_type(data);
   end

   data = to_cmm_shape(data, s);


   if isempty(s)
      if strcmp(t, 'T')
         cmm_fwrite_str(fid, data);
      elseif strcmp(t, 'B')
         cmm_fwrite_bool(fid, data);
      else
         fwrite(fid, data, from_cmm_type(t));
      end
      return
   else
      fwrite(fid,data,from_cmm_type(t));
   end
end


% flatten data to list r and determine size s
% appropiate for write out as in mmio.h 
function r = to_cmm_shape(data, s)
   if isscalar(data) || ischar(data)
      r = data;
      return
   end

   l = length(s);
   if l==1
      r = reshape(data, [1 s]);
      return
   end

   per = 1:l; 
   per(1) = 2; per(2) = 1;
   r = permute(data, per);
   r = reshape(r, [1 prod(s)]);
end

%write null terminated strings
function cmm_fwrite_str(fid, str)
   fwrite(fid, [str char(0)], 'char');
end

function cmm_fwrite_str_list(fid, data)
   for k=1:length(data)
      cmm_fwrite_str(fid, data{k})
   end
end

%write bools
function cmm_fwrite_bool(fid, b)
   if (b)
      fwrite(fid, 't', 'char');
   else
      fwrite(fid, 'f', 'char');
   end
end

function cmm_fwrite_bool_list(fid, data)
   for k=1:length(data)
      cmm_fwrite_bool(fid, data{k})
   end
end