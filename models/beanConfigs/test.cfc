component{
	this.definition = {
		schema: "default",
		table: "tbl_test",
		joins: [
			{
				table: "tbl_relation",
				on: "relation_id",
				from: "relationID",
				cols: "relationName, relationBody, relationName AS testAS"
			}
		],
		manyTomany: [
			{
				name: "categories",
				model: "category",
				intermediary: "rel_category_in_test",
				order: "categoryOrderKey ASC"
			}
		],
		specialColumns: [
			{
				column: "startDate",
				//insert: false,
				updateValue: function(bean){
					return dateAdd("yyyy", -10, now());
					return now();
				},
				//update: false
				"default": function(){
					return dateAdd("yyyy", -20, now());
				}
			}
		]
	};
}