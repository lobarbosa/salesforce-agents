global class MyXmlParser {
    public String xmlText { get; set; }
    
    static Pattern 
        boolPat = Pattern.compile('^(true|false)$'),  decPat = Pattern.compile('^[-+]?\\d+(\\.\\d+)?$'), 
        datePat = Pattern.compile('^\\d{4}.\\d{2}.\\d{2}$'), 
        timePat = Pattern.compile('^\\d{4}.\\d{2}.\\d{2} (\\d{2}:\\d{2}:\\d{2} ([-+]\\d{2}:\\d{2})?)?$');
    static Map<Object, Object> parseNode(Dom.XmlNode node, Map<Object, Object> parent) {
        for(Dom.XmlNode child: node.getChildElements()) {
            String nodeText = child.getText().trim(), name = child.getName();
            Object value = 
                String.isBlank(nodeText) ? null :
            boolPat.matcher(nodeText).find() ? (Object)Boolean.valueOf(nodeText) :
            decPat.matcher(nodeText).find() ? (Object)Decimal.valueOf(nodeText) :
            datePat.matcher(nodeText).find() ? (Object)Date.valueOf(nodeText) :
            timePat.matcher(nodeText).find() ? (Object)DateTime.valueOf(nodeText) : (Object)nodeText;
            if(value != null) {
                if(name.endsWith('s')) {
                    if(!parent.containsKey(name)) {
                        parent.put(name, new List<Object>());
                    }
                    ((List<Object>)parent.get(name)).add(value);
                } else {
                    parent.put(name, value);
                }
            } else if(child.getNodeType() == Dom.XmlNodeType.ELEMENT) {
                Map<Object, Object> temp = parseNode(child, new Map<Object, Object>());
                if(!temp.isEmpty()) {
                    if(parent.containsKey(name)) {
                        try {
                            ((List<Object>)parent.get(name)).add(temp);
                        } catch(Exception e) {
                            parent.put(name, new List<Object> { parent.get(name), temp });
                        }
                    } else {
                        parent.put(name, temp);
                    }
                }
            }
        }
        return parent;
    }
    global static Map<Object, Object> parseDocumentToMap(Dom.Document doc) {
        return parseNode(doc.getRootElement(), new Map<Object, Object>());
    }
    global static String parseDocumentToJson(Dom.Document doc) {
        return JSON.serializePretty(parseDocumentToMap(doc));
    }
}