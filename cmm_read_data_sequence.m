%read sequence of binary data form fid with headers hs
function data = cmm_read_data_sequence(fid, hs)
   l = length(hs);
   data = cell(1,l);
   k = 1;
   i = 1;
   while (~feof(fid))
      t = hs{k,1};
      s = hs{k,2};
      if ~isempty(s) && s(1) == -1
            s(1) = cmm_read_size(fid);
      end      
      dat = cmm_read_data(fid, t , s);
     
      if (isempty(s))
         data{k} = [data{k} dat];
      else
         if hs{k,2}(1) == -1
            data{k}{i} = dat;
         else
            data{k} = [data{k}; dat];
         end
      end
      k = mod(k, l) +1;
      if (k==1) i=i+1; end
   end
end