function is = ischarcell(data)
   is = 1;
   if ~iscell(data)
      is = 0;
      return
   end
   
   data = reshape(data, 1, numel(data));
   for k=1:length(data)
      if ~ischar(data{k})
         is = 0;
         return
      end
   end  
end     
